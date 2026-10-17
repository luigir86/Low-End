import 'dart:math' as math;
import 'dart:typed_data';

import '../features/metronome/feel.dart';
import '../features/metronome/time_signature.dart';
import 'drum_kit.dart';

/// The metronome's sound: a jazz drummer's ride cymbal, clearer than a click
/// yet warmer, so that it sits beside a piano without fighting it. The first
/// beat of the bar is the bell with the bass drum, the first pulse of a
/// group (6/8) in between, and the swing and the shuffle add the skip note,
/// softly, the hi-hat on 2 and 4 (swing) and a light snare on 2 and 4
/// (shuffle).
///
/// The strokes are recordings (see [DrumKit]); until [kit] is loaded, or
/// where it cannot be (a test, a phone that failed to read it), a ride made
/// in code stands in: a stick on a cymbal with its wash and a ring of
/// uneven partials.
abstract final class ClickSound {
  static const sampleRate = 44100;

  /// The recorded strokes, read once at launch (see `main`); null makes the
  /// synthesised ride play instead.
  static DrumKit? kit;

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
  static const _snarePeak = 0.4;
  static const _kickLevel = 0.6;

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
    final drums = kit;
    if (drums != null) {
      return _scaled(Float64List.fromList(drums.chick), _chickPeak);
    }
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
    final drums = kit;
    if (drums != null) {
      if (accent) {
        // The bell and the bass drum together, the bell on top.
        return _scaled(_sum(drums.bell, drums.kick, _kickLevel), _accentPeak);
      }
      return _scaled(
        Float64List.fromList(drums.ride),
        group ? _groupPeak : _plainPeak,
      );
    }
    if (accent) return ride(peak: _accentPeak, bell: 1);
    if (group) return ride(peak: _groupPeak, bell: 0.5);
    return ride(peak: _plainPeak);
  }

  /// The skip note of the swing and the shuffle: the ride, soft.
  static Float64List ghost() {
    final drums = kit;
    if (drums == null) return ride(peak: _ghostPeak);
    return _scaled(Float64List.fromList(drums.ghost), _ghostPeak);
  }

  /// The light snare on 2 and 4 of the shuffle; a short noise burst
  /// without the recordings.
  static Float64List snare() {
    final drums = kit;
    if (drums != null) {
      return _scaled(Float64List.fromList(drums.snare), _snarePeak);
    }
    return chick();
  }

  /// [a] and [b] (at level [k]) played together.
  static Float64List _sum(Float64List a, Float64List b, double k) {
    final out = Float64List(a.length > b.length ? a.length : b.length);
    for (var i = 0; i < a.length; i++) {
      out[i] += a[i];
    }
    for (var i = 0; i < b.length; i++) {
      out[i] += b[i] * k;
    }
    return out;
  }

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
    final backbeat = snare();
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
          // A light snare on 2 and 4, as in a blues shuffle.
          if (b.isOdd) mix(backbeat, at);
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
