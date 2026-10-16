import 'dart:math' as math;
import 'dart:typed_data';

import '../features/metronome/feel.dart';
import '../features/metronome/time_signature.dart';

/// The metronome's sound, made in code: a jazz drummer's ride cymbal, a
/// stick on it with its wash and a ring of uneven partials, clearer than a
/// click yet warmer, so that it sits beside a piano without fighting it.
/// The first beat of the bar is the bell, higher and brighter, the first
/// pulse of a group (6/8) in between, and the swing and the shuffle add the
/// skip note, softly, and the hi-hat on 2 and 4.
abstract final class ClickSound {
  static const sampleRate = 44100;

  /// How long a ride stroke rings; the bar is never shorter than a beat
  /// of 250 BPM, so a stroke ends before the next one in a plain bar.
  static const _rideLength = Duration(milliseconds: 230);
  static const _chickLength = Duration(milliseconds: 60);

  /// Loudness (peak, 0 to 1) of each kind of stroke.
  static const _plainPeak = 0.72;
  static const _groupPeak = 0.8;
  static const _accentPeak = 0.92;
  static const _ghostPeak = 0.42;
  static const _chickPeak = 0.6;

  // The partials of the ride: frequency, weight, decay (s).
  static const _ride = [
    (f: 620.0, a: 0.34, tau: 0.075),
    (f: 905.0, a: 0.3, tau: 0.09),
    (f: 1370.0, a: 0.3, tau: 0.08),
    (f: 2140.0, a: 0.26, tau: 0.065),
    (f: 3090.0, a: 0.2, tau: 0.05),
    (f: 4320.0, a: 0.13, tau: 0.04),
    (f: 5870.0, a: 0.08, tau: 0.03),
  ];

  // The bell: a few higher, longer partials, more of them on the "one".
  static const _bell = [
    (f: 1180.0, a: 0.34, tau: 0.13),
    (f: 1760.0, a: 0.22, tau: 0.11),
    (f: 2650.0, a: 0.14, tau: 0.08),
  ];

  /// One stroke of the ride, samples from -1 to 1, with a peak of [peak].
  /// [bell] is how much of the bell is in it, 0 to 1.
  static Float64List ride({required double peak, double bell = 0}) {
    final n = _rideLength.inMicroseconds * sampleRate ~/ 1000000;
    // The same noise every time: a stroke always sounds the same.
    final random = math.Random(7);
    final out = Float64List(n);
    var last = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final noise = random.nextDouble() * 2 - 1;
      // High-passed noise: the stick, then the wash of the cymbal.
      final bright = noise - last;
      last = noise;
      final stick = t < 0.005 ? bright * math.exp(-t / 0.0012) * 0.55 : 0.0;
      final wash = bright * math.exp(-t / 0.06) * 0.16;
      var body = 0.0;
      for (final p in _ride) {
        body += p.a * math.sin(2 * math.pi * p.f * t) * math.exp(-t / p.tau);
      }
      for (final p in _bell) {
        body +=
            bell * p.a * math.sin(2 * math.pi * p.f * t) * math.exp(-t / p.tau);
      }
      // A hair of attack, so that it does not click; the end fades out.
      final attack = math.min(1.0, t / 0.0004);
      final fade = math.min(1.0, (n - i) / (0.012 * sampleRate));
      out[i] = (stick + wash + body) * attack * fade;
    }
    return _scaled(out, peak);
  }

  /// The hi-hat closing with the foot (the "chick" on 2 and 4).
  static Float64List chick() {
    final n = _chickLength.inMicroseconds * sampleRate ~/ 1000000;
    final random = math.Random(11);
    final out = Float64List(n);
    var last = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final noise = random.nextDouble() * 2 - 1;
      final bright = noise - last;
      last = noise;
      final tone = 0.25 * math.sin(2 * math.pi * 7400 * t);
      final fade = math.min(1.0, (n - i) / (0.008 * sampleRate));
      out[i] = (bright + tone) * math.exp(-t / 0.014) * fade;
    }
    return _scaled(out, _chickPeak);
  }

  static Float64List _scaled(Float64List samples, double peak) {
    var top = 0.0;
    for (final v in samples) {
      top = math.max(top, v.abs());
    }
    if (top == 0) return samples;
    final k = peak / top;
    for (var i = 0; i < samples.length; i++) {
      samples[i] *= k;
    }
    return samples;
  }

  /// One stroke on a beat: the bell on the "one" ([accent]), a little less
  /// of it on the first pulse of a group ([group]), the plain ride
  /// otherwise.
  static Float64List click({required bool accent, bool group = false}) {
    if (accent) return ride(peak: _accentPeak, bell: 1);
    if (group) return ride(peak: _groupPeak, bell: 0.5);
    return ride(peak: _plainPeak);
  }

  /// The skip note of the swing and the shuffle: the ride, soft.
  static Float64List ghost() => ride(peak: _ghostPeak);

  /// One whole bar at [bpm] with [feel], a stroke at the start of each
  /// beat, as a WAV file: the audio engine loops it, so the beats stay
  /// exactly in time however busy the phone is. The swing and the shuffle
  /// only apply to bars counted in quarters; in eighths (6/8, 7/8) the bar
  /// is played straight.
  static Uint8List bar({
    required int bpm,
    TimeSignature signature = TimeSignature.fourFour,
    MetronomeFeel feel = MetronomeFeel.straight,
  }) {
    final beats = signature.beats;
    final beatLength = (sampleRate * 60 / bpm).round();
    final length = beatLength * beats;
    final samples = Float64List(length);
    // Strokes ring on past the end of their beat (and of the bar: the end
    // of the loop wraps round into its start), so they are added, not set.
    void mix(Float64List stroke, int at) {
      for (var i = 0; i < stroke.length; i++) {
        samples[(at + i) % length] += stroke[i];
      }
    }

    final plain = click(accent: false), accent = click(accent: true);
    final group = click(accent: false, group: true);
    final ghostNote = ghost();
    final hat = chick();
    final felt = signature.denominator == 8 ? MetronomeFeel.straight : feel;
    // The skip note is two thirds of the way through the beat.
    final skip = beatLength * 2 ~/ 3;
    for (var b = 0; b < beats; b++) {
      final stroke = switch (signature.accent(b)) {
        0 => accent,
        1 => group,
        _ => plain,
      };
      final at = b * beatLength;
      mix(stroke, at);
      switch (felt) {
        case MetronomeFeel.straight:
          break;
        case MetronomeFeel.swing:
          // Beats 2 and 4 (the only beat in a bar of one) get the skip
          // note, and the hi-hat falls on 2 and 4.
          if (b.isOdd || beats == 1) mix(ghostNote, at + skip);
          if (b.isOdd) mix(hat, at);
        case MetronomeFeel.shuffle:
          mix(ghostNote, at + skip);
      }
    }
    // Strokes pile up where they overlap: turn the bar down evenly if need
    // be, rather than clip.
    var top = 0.0;
    for (final v in samples) {
      top = math.max(top, v.abs());
    }
    if (top > 0.95) {
      final k = 0.95 / top;
      for (var i = 0; i < samples.length; i++) {
        samples[i] *= k;
      }
    }
    return wav(samples);
  }

  /// Wraps mono samples from -1 to 1 into a 16-bit PCM WAV file.
  static Uint8List wav(Float64List samples) {
    final data = samples.length * 2;
    final bytes = ByteData(44 + data);
    void ascii(int at, String text) {
      for (var i = 0; i < text.length; i++) {
        bytes.setUint8(at + i, text.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + data, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little); // Size of this chunk.
    bytes.setUint16(20, 1, Endian.little); // PCM.
    bytes.setUint16(22, 1, Endian.little); // Mono.
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // Bytes per second.
    bytes.setUint16(32, 2, Endian.little); // Bytes per sample.
    bytes.setUint16(34, 16, Endian.little); // Bits per sample.
    ascii(36, 'data');
    bytes.setUint32(40, data, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      final s = (samples[i].clamp(-1.0, 1.0) * 32767).round();
      bytes.setInt16(44 + i * 2, s, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}
