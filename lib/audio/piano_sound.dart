import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../features/metronome/time_signature.dart';
import 'click_sound.dart';

/// How the piano plays a chord or a progression, one bar after another.
enum PianoStyle {
  /// A single note kept sounding: struck again before it dies away, each
  /// ringing into the next, with no beat to it.
  drone,

  /// The chord struck once, on the "one", and left to ring for the bar.
  bar,

  /// The chord struck again on every beat, firmest on the "one".
  beat,

  /// One note of the chord on every beat, going up and down it.
  arpeggio,
}

/// A bar's worth of notes, as MIDI numbers (60 is middle C), root first.
typedef PianoChord = List<int>;

/// Recorded piano notes, a few of them, pitched up and down to cover the
/// range the drone plays in.
///
/// The recordings are the Salamander Grand Piano by Alexander Holm, a
/// Yamaha C5 (public domain since 2022; see the About page).
class PianoSamples {
  PianoSamples(this.notes);

  /// Mono samples at [sampleRate], by the MIDI number they were played at.
  final Map<int, Float32List> notes;

  static const sampleRate = 22050;

  /// The notes recorded, a minor third apart, from A2 to C6.
  static const roots = [
    45, 48, 51, 54, 57, 60, 63, 66, 69, 72, 75, 78, 81, 84, //
  ];

  static String assetOf(int midi) =>
      'assets/piano/${_names[midi % 12]}${midi ~/ 12 - 1}.wav'.replaceAll(
        '#',
        's',
      );

  static const _names = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
  ];

  /// Reads the recordings from the app's assets.
  static Future<PianoSamples> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final notes = <int, Float32List>{};
    for (final midi in roots) {
      final data = await b.load(assetOf(midi));
      notes[midi] = decodeWav(data.buffer.asUint8List(data.offsetInBytes));
    }
    return PianoSamples(notes);
  }

  /// Mono 16-bit samples of a WAV file, from -1 to 1.
  static Float32List decodeWav(Uint8List wav) {
    final view = ByteData.sublistView(wav);
    final n = (wav.length - 44) ~/ 2;
    return Float32List.fromList([
      for (var i = 0; i < n; i++)
        view.getInt16(44 + i * 2, Endian.little) / 32768,
    ]);
  }

  /// The recording nearest to [midi]: its number and its samples.
  (int, Float32List) nearest(int midi) {
    var best = notes.keys.first;
    for (final k in notes.keys) {
      if ((k - midi).abs() < (best - midi).abs()) best = k;
    }
    return (best, notes[best]!);
  }
}

/// Renders the bars of a chord progression played on the piano as one
/// looping recording, the same length as the metronome's bar so that the
/// two stay together however long they run.
abstract final class PianoSound {
  /// Level of each note before the sum is softened, to leave room for the
  /// others.
  static const _headroom = 0.42;

  /// How long a note rings before it is let go, in beats, and how long it
  /// takes to die away after that.
  static const _arpeggioHold = 2.0;
  static const _release = Duration(milliseconds: 160);

  /// How long, in seconds, a held single note is left before it is struck
  /// again: well within the length of the recordings.
  static const _droneRenew = 2.8;

  /// One loop of [chords] (one per bar) at [bpm] in [signature], as a WAV
  /// file. [a4] tunes the piano like the rest of the app.
  static Uint8List loopWav({
    required PianoSamples samples,
    required List<PianoChord> chords,
    required PianoStyle style,
    required int bpm,
    required TimeSignature signature,
    double a4 = 440,
  }) => ClickSound.wav(
    loop(
      samples: samples,
      chords: chords,
      style: style,
      bpm: bpm,
      signature: signature,
      a4: a4,
    ),
  );

  /// The samples of the loop, from -1 to 1 (see [loopWav]).
  static Float64List loop({
    required PianoSamples samples,
    required List<PianoChord> chords,
    required PianoStyle style,
    required int bpm,
    required TimeSignature signature,
    double a4 = 440,
  }) {
    final beat = (ClickSound.sampleRate * 60 / bpm).round();
    final barLength = beat * signature.beats;
    final out = Float64List(barLength * chords.length);
    final tuning = a4 / 440;
    final release = _release.inMicroseconds * ClickSound.sampleRate ~/ 1000000;

    void strike(int midi, double gain, int at, int hold) {
      final (root, source) = samples.nearest(midi);
      // Source samples per output sample: the pitch change, and the
      // difference of the two sample rates.
      final step =
          math.pow(2, (midi - root) / 12) *
          tuning *
          PianoSamples.sampleRate /
          ClickSound.sampleRate;
      final length = (source.length / step).floor();
      final sounding = math.min(length, hold + release);
      for (var i = 0; i < sounding; i++) {
        final position = i * step;
        final k = position.floor();
        final f = position - k;
        // Cubic interpolation between four neighbours.
        double s(int j) => source[(k + j).clamp(0, source.length - 1)];
        final y0 = s(-1), y1 = s(0), y2 = s(1), y3 = s(2);
        final value =
            y1 +
            0.5 *
                f *
                (y2 -
                    y0 +
                    f *
                        (2 * y0 -
                            5 * y1 +
                            4 * y2 -
                            y3 +
                            f * (3 * (y1 - y2) + y3 - y0)));
        // Let go: fade out over the release once the hold is over.
        final fade = i < hold ? 1.0 : 1 - (i - hold) / release;
        // The loop wraps round, so the end of a ringing note carries over
        // into the start of the next turn.
        out[(at + i) % out.length] += value * gain * fade * _headroom;
      }
    }

    for (var bar = 0; bar < chords.length; bar++) {
      final chord = chords[bar];
      for (var pulse = 0; pulse < signature.beats; pulse++) {
        final at = bar * barLength + pulse * beat;
        final accent = signature.accent(pulse);
        switch (style) {
          case PianoStyle.drone:
            // Struck every few beats, as often as the recording lasts, and
            // not at all between: each strike rings into the next one.
            final limit = _droneRenew * ClickSound.sampleRate;
            var every = 1;
            for (var d = 1; d <= signature.beats; d++) {
              if (signature.beats % d == 0 && d * beat <= limit) every = d;
            }
            // A bar not much longer than that is struck once, at its start.
            if (barLength <= limit * 1.25) every = signature.beats;
            if (pulse % every != 0) continue;
            final hold = every * beat * 2;
            strike(chord[0], 1, at, hold);
            strike(chord[0] - 12, 0.6, at, hold);
          case PianoStyle.bar:
            if (pulse != 0) continue;
            final hold = signature.beats * beat;
            for (var i = 0; i < chord.length; i++) {
              strike(chord[i], i == 0 ? 1 : 0.82, at, hold);
            }
            strike(chord[0] - 12, 0.6, at, hold);
          case PianoStyle.beat:
            // In eighths, the beat is the group: 6/8 is two beats.
            final isBeat = signature.denominator == 4 || accent < 2;
            if (!isBeat) continue;
            final gain = accent == 0 ? 1.0 : (accent == 1 ? 0.85 : 0.72);
            final next = _nextStrike(signature, pulse);
            for (var i = 0; i < chord.length; i++) {
              strike(chord[i], gain * (i == 0 ? 1 : 0.82), at, next * beat);
            }
            // The root again an octave down, for the weight.
            strike(chord[0] - 12, gain * 0.6, at, next * beat);
          case PianoStyle.arpeggio:
            final tone = _arpeggioTone(signature, pulse, chord.length);
            final gain = accent == 0 ? 1.0 : (accent == 1 ? 0.88 : 0.76);
            // A single note is quieter than a chord: lift it.
            strike(chord[tone], gain * 1.6, at, (_arpeggioHold * beat).round());
        }
      }
    }
    // Chords and ringing notes pile up: soften the peaks instead of
    // letting them clip.
    for (var i = 0; i < out.length; i++) {
      out[i] = _soft(out[i]);
    }
    return out;
  }

  /// Beats from [pulse] to the next strike of the chord in the bar, or to
  /// the end of the bar.
  static int _nextStrike(TimeSignature signature, int pulse) {
    var n = 1;
    while (pulse + n < signature.beats) {
      final next = pulse + n;
      if (signature.denominator == 4 || signature.accent(next) < 2) break;
      n++;
    }
    return n;
  }

  /// Which note of the chord (0 the root) the arpeggio plays on [pulse]:
  /// up and down the chord over the whole bar, or, where the bar is felt in
  /// groups (6/8), up from the root again in every group.
  static int _arpeggioTone(TimeSignature signature, int pulse, int tones) {
    if (signature.grouped) {
      var start = 0;
      for (final g in signature.groups) {
        if (pulse < start + g) return (pulse - start) % tones;
        start += g;
      }
    }
    if (tones < 2) return 0;
    final cycle = 2 * tones - 2;
    final i = pulse % cycle;
    return i < tones ? i : cycle - i;
  }

  /// Gentle saturation: linear for small values, never beyond ±1.
  static double _soft(double x) {
    const knee = 0.6;
    final a = x.abs();
    if (a <= knee) return x;
    final over = (a - knee) / (1 - knee);
    return x.sign * (knee + (1 - knee) * (over / (1 + over)));
  }
}
