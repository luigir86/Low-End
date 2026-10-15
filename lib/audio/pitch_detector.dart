import 'dart:math' as math;
import 'dart:typed_data';

/// Finds the fundamental frequency of a single note with the YIN algorithm
/// (de Cheveigné and Kawahara, 2002), which copes well with the strong
/// overtones of bass strings.
class PitchDetector {
  PitchDetector({
    required this.sampleRate,
    this.minFrequency = 28,
    this.maxFrequency = 700,
    this.threshold = 0.15,
    this.minLevel = 0.003,
    this.holdThreshold = 0.35,
  });

  final int sampleRate;

  /// Lowest frequency it can find; 28 Hz leaves room below the low B
  /// (30.9 Hz) of five-string basses.
  final double minFrequency;

  /// Highest frequency it can find; 700 Hz covers the top of the neck and
  /// the harmonics bassists tune with, and leaves out voices and hiss.
  final double maxFrequency;

  /// How periodic the sound must be, 0 to 1: lower is stricter.
  final double threshold;

  /// How periodic the sound must be to keep following a note already heard
  /// (see [detect]): a fading string is less clean than a fresh one.
  final double holdThreshold;

  /// Quieter sounds (root mean square, samples from -1 to 1) are ignored.
  final double minLevel;

  int get _maxLag => (sampleRate / minFrequency).ceil();
  int get _minLag => (sampleRate / maxFrequency).floor();

  /// Samples needed for one reading: three periods of the lowest note.
  int get windowSize => 3 * _maxLag;

  /// Returns the frequency in Hz, or null when [samples] hold no clear note
  /// (silence or noise). [samples] should be [windowSize] long.
  ///
  /// [expected] is the note heard just before, if any: when nothing passes
  /// the strict [threshold], a dip within a semitone of it that passes
  /// [holdThreshold] still counts, so a ringing string is followed until it
  /// has really faded.
  double? detect(Float64List samples, {double? expected}) {
    final n = samples.length;
    final maxLag = math.min(_maxLag, n ~/ 2);
    final width = n - maxLag;
    if (maxLag <= _minLag) return null;

    var energy = 0.0;
    for (var i = 0; i < n; i++) {
      energy += samples[i] * samples[i];
    }
    if (math.sqrt(energy / n) < minLevel) return null;

    // Cumulative mean normalised difference for each lag.
    final d = Float64List(maxLag + 1)..[0] = 1;
    var runningSum = 0.0;
    for (var lag = 1; lag <= maxLag; lag++) {
      var sum = 0.0;
      for (var i = 0; i < width; i++) {
        final delta = samples[i] - samples[i + lag];
        sum += delta * delta;
      }
      runningSum += sum;
      d[lag] = runningSum == 0 ? 1 : sum * lag / runningSum;
    }

    // The first dip under the threshold is the period; later dips are
    // multiples of it. A first dip above [maxFrequency] means a sound too
    // high for a bass (a voice, a whistle): its multiples would pass for a
    // lower note, so it is dropped whole, also when a note was heard just
    // before (the hold search below would otherwise find such a multiple).
    for (var lag = 2; lag < maxLag; lag++) {
      if (d[lag] >= threshold) continue;
      while (lag + 1 < maxLag && d[lag + 1] < d[lag]) {
        lag++;
      }
      if (lag < _minLag) return null;
      return sampleRate / _refine(d, lag);
    }

    if (expected == null) return null;
    final period = sampleRate / expected;
    final from = math.max((period / 1.06).floor(), math.max(_minLag, 2));
    final to = math.min((period * 1.06).ceil(), maxLag - 1);
    var best = -1;
    for (var lag = from; lag <= to; lag++) {
      if (best < 0 || d[lag] < d[best]) best = lag;
    }
    if (best < 0 || d[best] >= holdThreshold) return null;
    // The lowest point of the search range may sit on its edge, on the
    // slope of a dip outside it: only a real dip is worth placing finely.
    final isDip = d[best - 1] >= d[best] && d[best] <= d[best + 1];
    final hz = sampleRate / (isDip ? _refine(d, best) : best.toDouble());
    if (!hz.isFinite || hz < minFrequency || hz > maxFrequency) return null;
    return hz;
  }

  /// Places the minimum between samples with a parabola through its
  /// neighbours, for sub-sample precision. The shift is kept within one
  /// sample, where a flat or noisy curve could otherwise throw it far off.
  double _refine(Float64List d, int lag) {
    final a = d[lag - 1], b = d[lag], c = d[lag + 1];
    final curvature = a - 2 * b + c;
    if (curvature == 0) return lag.toDouble();
    final shift = (a - c) / (2 * curvature);
    return lag + (shift.isFinite ? shift.clamp(-1.0, 1.0) : 0.0);
  }
}
