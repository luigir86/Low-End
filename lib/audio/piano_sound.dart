import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../features/metronome/time_signature.dart';
import 'click_sound.dart';

/// How the piano plays a chord or a progression, one bar after another.
enum PianoStyle {
  /// A single note kept sounding: struck again before it dies away, each
  /// ringing into the next, with no beat to it.
  drone,

  /// The chord struck on the "one" and left to ring for the bar; in a bar
  /// too slow for it to last, struck again softly half way (or as often as
  /// it takes), so that the bar never ends in silence.
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
  /// Level of each note, to leave room for the others.
  static const _headroom = 0.42;

  /// Notes struck together up to which each keeps its full level; above,
  /// the chord is turned down as a whole (see [chordGain]).
  static const _fullChord = 4;

  /// The loudest the loop may get: a little under full scale.
  static const _ceiling = 0.97;

  /// The lowest note the root is doubled at, an octave down for weight (C2):
  /// below it the recordings would be pitched down too far to sound like a
  /// piano.
  static const _lowestDouble = 36;

  /// How long a note rings before it is let go, in beats, and how long it
  /// takes to die away after that.
  static const _arpeggioHold = 2.0;
  static const _release = Duration(milliseconds: 160);

  /// How long, in seconds, a held single note is left before it is struck
  /// again: well within the length of the recordings.
  static const _droneRenew = 2.8;

  /// How long, in seconds, a chord is left before it is struck again,
  /// softly, so that a slow bar does not end in silence: the recordings
  /// last 3.6 s, the last second fading out, and pitched up they are a
  /// little shorter.
  static const _chordRenew = 2.4;

  /// Level of a chord struck again within the bar, against its first
  /// strike.
  static const _renewGain = 0.6;

  /// The level of each note of a chord of [notes] struck together: full up
  /// to [_fullChord] notes, then lower, so that a fuller chord is not louder
  /// and its sum keeps clear of the top. A plain gain, which leaves the
  /// sound as it is, unlike softening the peaks, which would add partials
  /// and beat against the notes.
  @visibleForTesting
  static double chordGain(int notes) =>
      notes <= _fullChord ? 1 : math.sqrt(_fullChord / notes);

  /// Where, in samples from its start, a single note held through a bar of
  /// [barLength] samples is struck: as seldom as the recordings allow,
  /// evenly, wherever that falls in the bar (on a beat or not), so that the
  /// note has no beat to it; once a bar if the bar is not much longer than
  /// a recording rings.
  @visibleForTesting
  static List<int> droneStrikes(int barLength) {
    final limit = _droneRenew * ClickSound.sampleRate;
    final count = barLength <= limit * 1.25 ? 1 : (barLength / limit).ceil();
    return [for (var i = 0; i < count; i++) (i * barLength / count).round()];
  }

  /// The pulses, from [from] up to [to] (not included), on which a chord
  /// struck at [from] and held until [to] is struck again so that it never
  /// rings longer than the recordings last: as few as needed, as evenly as
  /// the pulses of [beat] samples allow, starting with [from].
  @visibleForTesting
  static List<int> chordStrikes(int from, int to, int beat) {
    final limit = _chordRenew * ClickSound.sampleRate;
    final span = to - from;
    for (var count = 1; count < span; count++) {
      final at = [for (var i = 0; i < count; i++) from + i * span ~/ count];
      var longest = 0;
      for (var i = 0; i < count; i++) {
        final end = i + 1 < count ? at[i + 1] : to;
        longest = math.max(longest, end - at[i]);
      }
      if (longest * beat <= limit) return at;
    }
    return [for (var p = from; p < to; p++) p];
  }

  /// One loop of [chords] (one per bar) at [bpm] in [signature], as a WAV
  /// file. [a4] tunes the piano like the rest of the app.
  static Uint8List loopWav({
    required PianoSamples samples,
    required List<PianoChord> chords,
    required PianoStyle style,
    required int bpm,
    required TimeSignature signature,
    double a4 = 440,
    bool rootless = false,
  }) => ClickSound.wav(
    loop(
      samples: samples,
      chords: chords,
      style: style,
      bpm: bpm,
      signature: signature,
      a4: a4,
      rootless: rootless,
    ),
  );

  /// The samples of the loop, from -1 to 1 (see [loopWav]). With [rootless],
  /// the chords have no root to double an octave down: their first note is
  /// not one. The bar keeps the metronome's length.
  static Float64List loop({
    required PianoSamples samples,
    required List<PianoChord> chords,
    required PianoStyle style,
    required int bpm,
    required TimeSignature signature,
    double a4 = 440,
    bool rootless = false,
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

    /// The chord, with its root again an octave down for the weight, struck
    /// at [at] at [gain] and held for [hold] samples.
    void strikeChord(PianoChord chord, double gain, int at, int hold) {
      final doubled = !rootless && chord[0] - 12 >= _lowestDouble;
      final level = gain * chordGain(chord.length + (doubled ? 1 : 0));
      for (var i = 0; i < chord.length; i++) {
        strike(chord[i], level * (i == 0 ? 1 : 0.82), at, hold);
      }
      if (doubled) strike(chord[0] - 12, level * 0.6, at, hold);
    }

    /// The chord struck on [pulse] and held until [until] (a pulse, or the
    /// end of the bar), struck again softly in between when that is longer
    /// than the recordings ring.
    void holdChord(
      PianoChord chord,
      double gain,
      int start,
      int pulse,
      int until,
    ) {
      final strikes = chordStrikes(pulse, until, beat);
      for (var i = 0; i < strikes.length; i++) {
        final end = i + 1 < strikes.length ? strikes[i + 1] : until;
        strikeChord(
          chord,
          i == 0 ? gain : gain * _renewGain,
          start + strikes[i] * beat,
          (end - strikes[i]) * beat,
        );
      }
    }

    for (var bar = 0; bar < chords.length; bar++) {
      final chord = chords[bar];
      final start = bar * barLength;
      switch (style) {
        case PianoStyle.drone:
          // Struck as seldom as the recording allows, wherever that falls
          // in the bar, and not at all between: each strike rings into the
          // next one.
          final strikes = droneStrikes(barLength);
          final every = barLength ~/ strikes.length;
          for (final at in strikes) {
            strike(chord[0], 1, start + at, every * 2);
            if (chord[0] - 12 >= _lowestDouble) {
              strike(chord[0] - 12, 0.6, start + at, every * 2);
            }
          }
        case PianoStyle.bar:
          holdChord(chord, 1, start, 0, signature.beats);
        case PianoStyle.beat:
          for (var pulse = 0; pulse < signature.beats; pulse++) {
            final accent = signature.accent(pulse);
            // In eighths, the beat is the group: 6/8 is two beats.
            final isBeat = signature.denominator != 8 || accent < 2;
            if (!isBeat) continue;
            final gain = accent == 0 ? 1.0 : (accent == 1 ? 0.85 : 0.72);
            final next = _nextStrike(signature, pulse);
            holdChord(chord, gain, start, pulse, pulse + next);
          }
        case PianoStyle.arpeggio:
          // The notes go up and down the chord one after another.
          var count = 0;
          for (var pulse = 0; pulse < signature.beats; pulse++) {
            final accent = signature.accent(pulse);
            final tone = _arpeggioTone(signature, count++, chord.length);
            final gain = accent == 0 ? 1.0 : (accent == 1 ? 0.88 : 0.76);
            final hold = (_arpeggioHold * beat).round();
            // A single note is quieter than a chord: lift it.
            strike(chord[tone], gain * 1.6, start + pulse * beat, hold);
          }
      }
    }
    // Chords and ringing notes pile up: where they would go past the top,
    // turn the whole loop down, evenly, rather than bend the peaks.
    var peak = 0.0;
    for (final v in out) {
      peak = math.max(peak, v.abs());
    }
    if (peak > _ceiling) {
      final scale = _ceiling / peak;
      for (var i = 0; i < out.length; i++) {
        out[i] *= scale;
      }
    }
    return out;
  }

  /// Beats from [pulse] to the next strike of the chord in the bar, or to
  /// the end of the bar.
  static int _nextStrike(TimeSignature signature, int pulse) {
    var n = 1;
    while (pulse + n < signature.beats) {
      final next = pulse + n;
      if (signature.denominator != 8 || signature.accent(next) < 2) break;
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
}
