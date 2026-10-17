import 'dart:math' as math;
import 'dart:typed_data';

import '../features/metronome/feel.dart';
import '../features/metronome/time_signature.dart';

/// The metronome click, made in code: a short, dry woodblock-like tick, the
/// kind DAWs use, pitched in the middle so it cuts through without tiring
/// the ear. The first beat of the bar is a little higher, to hear the "one".
/// In the swing feel the skip note is the same tick, softer.
abstract final class ClickSound {
  static const sampleRate = 44100;

  /// Pitch of the plain click and of the accented first beat, in Hz.
  static const plainHz = 800.0;
  static const accentHz = 1000.0;

  /// Pitch of the first pulse of each group, in 6/8 and the like.
  static const groupHz = 900.0;

  static const _length = Duration(milliseconds: 60);

  /// Level of the skip note of the swing, against a plain click.
  static const _skipLevel = 0.45;

  /// One click, samples from -1 to 1.
  static Float64List click({required bool accent, double? hz}) {
    final f = hz ?? (accent ? accentHz : plainHz);
    final n = _length.inMicroseconds * sampleRate ~/ 1000000;
    final random = math.Random(accent ? 1 : 2);
    return Float64List.fromList([
      for (var i = 0; i < n; i++) _sample(i / sampleRate, f, random),
    ]);
  }

  static double _sample(double t, double f, math.Random random) {
    // Half a millisecond of attack, then a quick decay: a tick, not a beep.
    final envelope = (1 - math.exp(-t / 0.0005)) * math.exp(-t / 0.018);
    final body =
        math.sin(2 * math.pi * f * t) +
        // A faster-fading inharmonic partial gives the wooden colour.
        0.4 * math.sin(2 * math.pi * f * 2.76 * t) * math.exp(-t / 0.008);
    // A touch of noise for the first two milliseconds: the strike.
    final strike = t < 0.002 ? (random.nextDouble() * 2 - 1) * 0.3 : 0.0;
    return 0.8 * envelope * (body / 1.4) + strike * (1 - t / 0.002);
  }

  /// The skip note of the swing: a plain click, softer.
  static Float64List skip() {
    final tick = click(accent: false);
    for (var i = 0; i < tick.length; i++) {
      tick[i] *= _skipLevel;
    }
    return tick;
  }

  /// One whole bar at [bpm] with [feel], a click at the start of each beat,
  /// as a WAV file: the audio engine loops it, so the beats stay exactly in
  /// time however busy the phone is. The swing adds the skip note two
  /// thirds of the way through beats 2 and 4, and only applies to bars
  /// counted in quarters; in eighths (6/8, 7/8) the bar is played straight.
  static Uint8List bar({
    required int bpm,
    TimeSignature signature = TimeSignature.fourFour,
    MetronomeFeel feel = MetronomeFeel.straight,
  }) {
    final beats = signature.beats;
    final beatLength = (sampleRate * 60 / bpm).round();
    final samples = Float64List(beatLength * beats);
    final plain = click(accent: false), accent = click(accent: true);
    final group = click(accent: false, hz: groupHz);
    final skipNote = skip();
    final felt = signature.denominator == 8 ? MetronomeFeel.straight : feel;
    for (var b = 0; b < beats; b++) {
      final tick = switch (signature.accent(b)) {
        0 => accent,
        1 => group,
        _ => plain,
      };
      samples.setRange(b * beatLength, b * beatLength + tick.length, tick);
      if (felt.skipsAfter(b, beats)) {
        final at = b * beatLength + MetronomeFeel.skipAt(beatLength);
        samples.setRange(at, at + skipNote.length, skipNote);
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
