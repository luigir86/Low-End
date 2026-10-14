import 'dart:math' as math;
import 'dart:typed_data';

/// Finds the fundamental frequency of a single note with the YIN algorithm
/// (de Cheveigné and Kawahara, 2002), which copes well with the strong
/// overtones of bass strings.
class PitchDetector {
  PitchDetector({
    required this.sampleRate,
    this.minFrequency = 28,
    this.maxFrequency = 1000,
    this.threshold = 0.15,
    this.minLevel = 0.005,
  });

  final int sampleRate;

  /// Lowest frequency it can find; 28 Hz leaves room below the low B
  /// (30.9 Hz) of five-string basses.
  final double minFrequency;
  final double maxFrequency;

  /// How periodic the sound must be, 0 to 1: lower is stricter.
  final double threshold;

  /// Quieter sounds (root mean square, samples from -1 to 1) are ignored.
  final double minLevel;

  int get _maxLag => (sampleRate / minFrequency).ceil();
  int get _minLag => (sampleRate / maxFrequency).floor();

  /// Samples needed for one reading: three periods of the lowest note.
  int get windowSize => 3 * _maxLag;

  /// Returns the frequency in Hz, or null when [samples] hold no clear note
  /// (silence or noise). [samples] should be [windowSize] long.
  double? detect(Float64List samples) {
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
    // multiples of it.
    for (var lag = math.max(_minLag, 2); lag < maxLag; lag++) {
      if (d[lag] >= threshold) continue;
      while (lag + 1 < maxLag && d[lag + 1] < d[lag]) {
        lag++;
      }
      return sampleRate / _refine(d, lag);
    }
    return null;
  }

  /// Places the minimum between samples with a parabola through its
  /// neighbours, for sub-sample precision.
  double _refine(Float64List d, int lag) {
    final a = d[lag - 1], b = d[lag], c = d[lag + 1];
    final curvature = a - 2 * b + c;
    if (curvature == 0) return lag.toDouble();
    return lag + (a - c) / (2 * curvature);
  }
}
