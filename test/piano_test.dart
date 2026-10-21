import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/click_sound.dart';
import 'package:low_end/audio/loop_transport.dart';
import 'package:low_end/audio/piano_output.dart';
import 'package:low_end/audio/piano_sound.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/features/metronome/time_signature.dart';
import 'package:low_end/features/tuner/drone/drone_controller.dart';
import 'package:low_end/features/tuner/drone/harmony.dart';

/// Pure tones in place of the piano: each recorded note a sine at its own
/// pitch, a second long, so what is played can be told by its frequency.
PianoSamples _tones() {
  const rate = PianoSamples.sampleRate;
  return PianoSamples({
    for (final midi in PianoSamples.roots)
      midi: Float32List.fromList([
        for (var i = 0; i < rate; i++)
          0.5 *
              math.sin(
                2 * math.pi * 440 * math.pow(2, (midi - 69) / 12) * i / rate,
              ),
      ]),
  });
}

double _hz(int midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

/// The pitch heard in [loop] from [from] for [length] samples, by counting
/// the times it crosses zero.
double _pitch(Float64List loop, int from, int length) {
  var crossings = 0;
  for (var i = from + 1; i < from + length; i++) {
    if ((loop[i - 1] < 0) != (loop[i] < 0)) crossings++;
  }
  return crossings / 2 / (length / ClickSound.sampleRate);
}

double _energy(Float64List loop, int from, int length) {
  var e = 0.0;
  for (var i = from; i < from + length; i++) {
    e += loop[i] * loop[i];
  }
  return e;
}

void main() {
  final samples = _tones();
  const cMajor = [60, 64, 67];

  group('the piano loop', () {
    test('doubles the root an octave down, unless it is too low', () {
      Float64List render(List<int> chord) => PianoSound.loop(
        samples: samples,
        chords: [chord],
        style: PianoStyle.bar,
        bpm: 120,
        signature: TimeSignature.fourFour,
      );
      // How strong [hz] is in [s], by correlation with a sine.
      double power(Float64List s, double hz) {
        var re = 0.0, im = 0.0;
        for (var i = 0; i < s.length; i++) {
          final a = 2 * math.pi * hz * i / ClickSound.sampleRate;
          re += s[i] * math.cos(a);
          im += s[i] * math.sin(a);
        }
        return re * re + im * im;
      }

      // C4: the C3 below it is struck too.
      final c = render(cMajor);
      expect(power(c, _hz(48)), greaterThan(power(c, _hz(60)) * 0.05));
      // A2: the A1 would be a piano slowed down to a rumble, so it is left
      // out.
      final a = render(const [45, 61, 64]);
      expect(power(a, _hz(33)), lessThan(power(a, _hz(45)) * 0.01));
    });

    test('is whole bars of the metronome length', () {
      final loop = PianoSound.loop(
        samples: samples,
        chords: [cMajor, cMajor, cMajor],
        style: PianoStyle.beat,
        bpm: 90,
        signature: TimeSignature.threeFour,
      );
      final beat = (ClickSound.sampleRate * 60 / 90).round();
      expect(loop.length, beat * 3 * 3);
      expect(loop.every((v) => v.abs() <= 1), isTrue);
    });

    test('4/4 strikes the chord on every beat, the "one" firmest', () {
      final loop = PianoSound.loop(
        samples: samples,
        chords: [cMajor],
        style: PianoStyle.beat,
        bpm: 120,
        signature: TimeSignature.fourFour,
      );
      final beat = ClickSound.sampleRate ~/ 2;
      for (var b = 0; b < 4; b++) {
        expect(_energy(loop, b * beat, 2000), greaterThan(1));
      }
      expect(_energy(loop, 0, 2000), greaterThan(_energy(loop, beat, 2000)));
    });

    test('6/8 strikes only at the first pulse of each group', () {
      PianoSound.loop(
        samples: samples,
        chords: [cMajor],
        style: PianoStyle.beat,
        bpm: 240,
        signature: TimeSignature.sixEight,
      );
      // One strike per group, so the chord is struck twice in the bar: the
      // later pulses only ring on. Silence the notes a pulse after the
      // second group starts to see the first group's chord let go.
      final loop = PianoSound.loop(
        samples: samples,
        chords: [cMajor],
        style: PianoStyle.beat,
        bpm: 600,
        signature: TimeSignature.sixEight,
      );
      final pulse = (ClickSound.sampleRate * 60 / 600).round();
      // Each group lasts three pulses: its chord is held for all three.
      expect(_energy(loop, pulse * 2, 400), greaterThan(0.01));
      expect(_energy(loop, 3 * pulse, 400), greaterThan(0.01));
    });

    test('a chord a bar rings for the whole bar from the "one"', () {
      final loop = PianoSound.loop(
        samples: samples,
        chords: [cMajor],
        style: PianoStyle.bar,
        bpm: 240,
        signature: TimeSignature.fourFour,
      );
      final beat = ClickSound.sampleRate ~/ 4;
      // Sounding from the first beat to the last: struck once, held for the bar.
      for (var b = 0; b < 4; b++) {
        expect(_energy(loop, b * beat, 2000), greaterThan(1));
      }
    });

    test('a single note is struck once a bar and kept sounding', () {
      final loop = PianoSound.loop(
        samples: samples,
        chords: [
          [69],
        ],
        style: PianoStyle.drone,
        bpm: 240,
        signature: TimeSignature.fourFour,
      );
      final beat = ClickSound.sampleRate ~/ 4;
      // Sounding from the first beat to the last, with no new start between.
      for (var b = 0; b < 4; b++) {
        expect(_energy(loop, b * beat, 2000), greaterThan(1));
      }
      expect(loop.length, beat * 4);
    });

    test('an arpeggio plays one note a beat, up and down the chord', () {
      final loop = PianoSound.loop(
        samples: samples,
        chords: [cMajor],
        style: PianoStyle.arpeggio,
        bpm: 60,
        signature: TimeSignature.fourFour,
      );
      final beat = ClickSound.sampleRate;
      // Root, third, fifth, third. Each note rings on into the next, so
      // the pitch just after a strike is somewhere between the new note
      // and the one before.
      const expected = [60, 64, 67, 64];
      for (var b = 0; b < 4; b++) {
        final pitch = _pitch(loop, b * beat + 100, 800);
        final now = _hz(expected[b]);
        final before = _hz(expected[(b + 3) % 4]);
        final low = math.min(now, before) * 0.85;
        final high = math.max(now, before) * 1.15;
        expect(
          pitch,
          allOf(greaterThan(low), lessThan(high)),
          reason: 'beat $b: heard $pitch Hz',
        );
      }
    });

    test('6/8 arpeggios start from the root again in each group', () {
      final loop = PianoSound.loop(
        samples: samples,
        chords: [cMajor],
        style: PianoStyle.arpeggio,
        bpm: 120,
        signature: TimeSignature.sixEight,
      );
      final pulse = ClickSound.sampleRate ~/ 2;
      final first = _pitch(loop, 100, 600);
      final fourth = _pitch(loop, 3 * pulse + 100, 600);
      // Both groups open on the root (the fourth over the tail of the
      // fifth, so not exactly): the second is nearer the first than the
      // note that would follow it in a plain climb.
      expect((fourth - first).abs(), lessThan(first * 0.4));
    });

    test('a ringing note wraps round into the start of the loop', () {
      final loop = PianoSound.loop(
        samples: samples,
        chords: [cMajor],
        style: PianoStyle.arpeggio,
        bpm: 240,
        signature: TimeSignature.twoFour,
      );
      expect(_energy(loop, 0, 200), greaterThan(0));
      expect(loop.length, (ClickSound.sampleRate * 60 / 240).round() * 2);
    });

    test('a bar of one beat (1/1) works in every style', () {
      for (final style in PianoStyle.values) {
        final loop = PianoSound.loop(
          samples: samples,
          chords: [cMajor, cMajor],
          style: style,
          bpm: 120,
          signature: TimeSignature.oneOne,
        );
        // Two bars of one beat each.
        expect(loop.length, ClickSound.sampleRate, reason: '$style');
        expect(_energy(loop, 0, 200), greaterThan(0), reason: '$style');
        expect(loop.every((v) => v.isFinite), isTrue, reason: '$style');
      }
    });

    test('is tuned by the reference A', () {
      Float64List at(double a4) => PianoSound.loop(
        samples: samples,
        chords: [cMajor],
        style: PianoStyle.beat,
        bpm: 60,
        signature: TimeSignature.twoFour,
        a4: a4,
      );
      final ratio =
          _pitch(at(466.16), 3000, 4000) / _pitch(at(440), 3000, 4000);
      // A semitone up.
      expect(ratio, closeTo(1.0595, 0.03));
    });

    test('a slow bar is struck again softly, never left silent', () {
      // 4/4 at 50: a bar of 4.8 s, longer than a recording rings.
      final beat = (ClickSound.sampleRate * 60 / 50).round();
      expect(PianoSound.chordStrikes(0, 4, beat), [0, 2]);
      // 5/4 at 40: beats of 1.5 s, two of them too long, so every beat.
      final slow = (ClickSound.sampleRate * 60 / 40).round();
      expect(PianoSound.chordStrikes(0, 5, slow), [0, 1, 2, 3, 4]);
      // At 120 once a bar is enough, as before.
      expect(PianoSound.chordStrikes(0, 4, ClickSound.sampleRate ~/ 2), [0]);
      // A long group of 7/8 in Chord on every beat: split as well.
      final eighth = (ClickSound.sampleRate * 60 / 60).round();
      expect(PianoSound.chordStrikes(4, 7, eighth), [4, 5]);

      // At 30 BPM in 4/4 a beat lasts 2 s, so even two beats are too long
      // for a recording: the chord is struck again, softly, on each beat,
      // and sounds again in the second half of the bar.
      final loop = PianoSound.loop(
        samples: samples,
        chords: [cMajor],
        style: PianoStyle.bar,
        bpm: 30,
        signature: TimeSignature.fourFour,
      );
      final two = ClickSound.sampleRate * 2;
      expect(_energy(loop, 0, 2000), greaterThan(1));
      expect(_energy(loop, 2 * two, 2000), greaterThan(0.1));
      // Softer than the first strike.
      expect(_energy(loop, 2 * two, 2000), lessThan(_energy(loop, 0, 2000)));
    });

    test('a held note is not struck on every beat of a slow 5/4 or 3/4', () {
      int bar(int bpm, int beats) =>
          (ClickSound.sampleRate * 60 / bpm).round() * beats;
      // 5/4 at 60: a 5 s bar, struck twice, half way, between two beats.
      final five = PianoSound.droneStrikes(bar(60, 5));
      expect(five, hasLength(2));
      expect(five[1], bar(60, 5) ~/ 2);
      // 3/4 at 50 (3.6 s): twice, not three times.
      expect(PianoSound.droneStrikes(bar(50, 3)), hasLength(2));
      // 7/8 at ♪ = 100 (4.2 s): twice, not seven times.
      expect(PianoSound.droneStrikes(bar(100, 7)), hasLength(2));
      // A 4/4 at 80 (3 s) is struck once, as before.
      expect(PianoSound.droneStrikes(bar(80, 4)), [0]);
      // Never more often than the recordings need, whatever the bar.
      final long = bar(30, 12);
      final strikes = PianoSound.droneStrikes(long);
      expect(long / strikes.length, greaterThan(2 * ClickSound.sampleRate));
    });

    test('chords are turned down evenly, not bent at the peaks', () {
      // Loud test notes, so that the sum goes past the top.
      PianoSamples loud(double level) => PianoSamples({
        for (final e in samples.notes.entries)
          e.key: Float32List.fromList([for (final v in e.value) v * level]),
      });
      Float64List render(double level) => PianoSound.loop(
        samples: loud(level),
        chords: [
          [60, 64, 67],
        ],
        style: PianoStyle.beat,
        bpm: 120,
        signature: TimeSignature.fourFour,
      );
      final quiet = render(0.2), strong = render(2);
      final peak = strong.map((v) => v.abs()).reduce(math.max);
      expect(peak, lessThanOrEqualTo(0.97 + 1e-9));
      expect(peak, greaterThan(0.9));
      // The loud loop is the quiet one scaled: the same shape, no new
      // partials.
      final ratio = strong[1000] / quiet[1000];
      for (var i = 0; i < quiet.length; i += 97) {
        if (quiet[i].abs() < 1e-4) continue;
        // (The test notes are 32-bit floats: equal to a few millionths.)
        expect(
          strong[i] / quiet[i],
          closeTo(ratio, ratio * 1e-4),
          reason: 'at $i',
        );
      }
      // And a quiet one is left as it is.
      expect(quiet.map((v) => v.abs()).reduce(math.max), lessThan(0.97));
    });

    test('a fuller chord is no louder: the level goes down with the notes', () {
      expect(PianoSound.chordGain(3), 1);
      expect(PianoSound.chordGain(4), 1);
      expect(PianoSound.chordGain(5), lessThan(1));
      expect(
        PianoSound.chordGain(5) * 5,
        greaterThan(PianoSound.chordGain(4) * 4),
      );
    });

    test('the WAV is a valid 16-bit mono file', () {
      final wav = PianoSound.loopWav(
        samples: samples,
        chords: [cMajor],
        style: PianoStyle.beat,
        bpm: 120,
        signature: TimeSignature.fourFour,
      );
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect((wav.length - 44) ~/ 2, ClickSound.sampleRate * 2);
    });
  });

  group('the drone on the piano', () {
    late SilentToneOutput tone;
    late SilentPianoOutput piano;
    late _Clock clock;
    late DroneController drone;

    setUp(() {
      tone = SilentToneOutput();
      piano = SilentPianoOutput();
      clock = _Clock();
      drone = DroneController(tone, clock: clock, piano: piano);
    });

    test('opens on the piano, a chord on every beat', () {
      expect(drone.style, DroneStyle.beat);
    });

    test('a chord every bar is struck once and left to ring', () async {
      drone.setVoicing(DroneVoicing.chord);
      drone.setStyle(DroneStyle.held);
      await drone.tapNote(0);
      expect(piano.style, PianoStyle.bar);
      expect(tone.frequencies, isEmpty);
    });

    test('a chord struck on every beat, at the metronome tempo', () async {
      drone.setVoicing(DroneVoicing.chord);
      drone.setStyle(DroneStyle.beat);
      await drone.tapNote(0); // C
      expect(piano.chords, [
        [48, 64, 67],
      ]);
      expect(piano.style, PianoStyle.beat);
      expect(piano.bpm, 120);
      expect(piano.signature, TimeSignature.fourFour);
      // The tone is silent, and the piano starts on the first beat.
      expect(tone.frequencies, isEmpty);
      expect(piano.startAt, Duration.zero);
    });
    test('a seventh chord adds the seventh', () async {
      drone.setVoicing(DroneVoicing.chord);
      drone.setChord(ChordQuality.dominant);
      drone.setStyle(DroneStyle.arpeggio);
      await drone.tapNote(7); // G
      // G in the bass, then D F B close together above it.
      expect(piano.chords!.single, [55, 62, 65, 71]);
      expect(piano.style, PianoStyle.arpeggio);
    });

    test('a progression is one chord a bar, as a loop', () async {
      drone.setVoicing(DroneVoicing.progression);
      drone.setStyle(DroneStyle.beat);
      await drone.tapNote(0);
      // II–V–I in C: Dm7, G7, Cmaj7.
      // Close together: the hand stays in one place from chord to chord.
      expect(piano.chords, [
        [50, 60, 65, 69],
        [55, 62, 65, 71],
        [48, 64, 67, 71],
      ]);
    });

    test('the root in the bass, the rest close together above it', () async {
      drone.setVoicing(DroneVoicing.chord);
      drone.setChord(ChordQuality.dominant);
      drone.setStyle(DroneStyle.beat);
      await drone.tapNote(7); // G7: G3, then F, B and D from C4 up.
      expect(piano.chords!.single, [55, 62, 65, 71]);
    });

    test('every chord sits in the same octave of keys when close', () async {
      drone.setVoicing(DroneVoicing.chord);
      drone.setStyle(DroneStyle.beat);
      for (var pc = 0; pc < 12; pc++) {
        await drone.tapNote(pc);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        final upper = piano.chords!.single.sublist(1);
        for (final n in upper) {
          expect(n, inInclusiveRange(60, 71), reason: 'pitch class $pc');
        }
        // The notes are what the chord says, wherever they sit.
        expect({
          for (final n in piano.chords!.single) n % 12,
        }, drone.chordTones.union({pc}));
        await drone.stop();
      }
    });

    test('the root is in octave 3, and the chord stays above it', () async {
      drone.setVoicing(DroneVoicing.chord);
      drone.setStyle(DroneStyle.beat);
      expect(drone.octave, 3);
      expect(drone.note.octave, 3);
      await drone.tapNote(9); // A
      // A3 in the bass, then C♯ and E from C4 up.
      expect(piano.chords!.single, [57, 61, 64]);
      expect(drone.frequency, closeTo(220, 0.01));
      await drone.stop();
    });

    test("a single note is played by the piano too", () async {
      await drone.tapNote(9); // A
      expect(piano.chords, [
        [57],
      ]);
      // Kept sounding, not struck on every beat, whatever the style.
      expect(piano.style, PianoStyle.drone);
      expect(tone.frequencies, isEmpty);
    });

    test('in 6/8 the piano plays the clicks: three a beat', () async {
      drone.setVoicing(DroneVoicing.chord);
      clock.signature = TimeSignature.sixEight;
      clock.bpm = 60;
      clock.announce();
      await drone.tapNote(0);
      expect(piano.bpm, 180);
    });

    test('holding + renders the piano only as often as it can', () async {
      final slow = _SlowPianoOutput();
      final d = DroneController(tone, clock: clock, piano: slow);
      d.setVoicing(DroneVoicing.chord);
      await d.tapNote(0);
      final plays = slow.plays;
      for (var i = 0; i < 20; i++) {
        clock.bpm += 5;
        clock.announce();
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // One render under way, then one with the latest tempo: not twenty.
      expect(slow.plays - plays, lessThanOrEqualTo(2));
      expect(slow.bpm, 220);
      await d.stop();
    });

    test('a new tempo carries on, a new time signature starts over', () async {
      drone.setVoicing(DroneVoicing.chord);
      drone.setStyle(DroneStyle.beat);
      await drone.tapNote(0);
      final plays = piano.plays;
      clock.bpm = 100;
      clock.announce();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(piano.plays, plays + 1);
      expect(piano.bpm, 100);
      expect(piano.startAt, isNull);

      clock.signature = TimeSignature.sixEight;
      clock.announce();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(piano.signature, TimeSignature.sixEight);
      expect(piano.startAt, Duration.zero);
    });

    test('changing the key restarts from the first beat', () async {
      drone.setVoicing(DroneVoicing.chord);
      drone.setStyle(DroneStyle.beat);
      await drone.tapNote(0);
      await drone.tapNote(2); // D
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(piano.chords!.single.first, 50);
      expect(piano.startAt, Duration.zero);
    });

    test('stopping silences the piano', () async {
      drone.setVoicing(DroneVoicing.chord);
      drone.setStyle(DroneStyle.beat);
      await drone.tapNote(0);
      await drone.stop();
      expect(piano.chords, isNull);
    });

    test(
      "without a piano it falls back to the tone, and offers no styles",
      () async {
        final plain = DroneController(tone);
        expect(plain.hasPiano, isFalse);
        await plain.tapNote(9);
        expect(tone.frequencies, isNotEmpty);
      },
    );

    testWidgets('a progression follows its own bars, after the wait', (
      tester,
    ) async {
      piano.delay = const Duration(seconds: 1);
      drone.setVoicing(DroneVoicing.progression);
      drone.setStyle(DroneStyle.beat);
      await drone.tapNote(0);
      await tester.pump();
      expect(drone.step, 0);
      // The first chord comes in after a second, and the next a bar (2 s
      // at 120 BPM in 4/4) after that.
      await tester.pump(const Duration(seconds: 2));
      expect(drone.step, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(drone.step, 1);
      await drone.stop();
    });
  });
}

/// A piano that takes a while to get each loop ready, as rendering does.
class _SlowPianoOutput extends SilentPianoOutput {
  @override
  Future<LoopStart> play({
    required List<PianoChord> chords,
    required PianoStyle style,
    required int bpm,
    required TimeSignature signature,
    required double a4,
    required double volume,
    Duration? startAt,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return super.play(
      chords: chords,
      style: style,
      bpm: bpm,
      signature: signature,
      a4: a4,
      volume: volume,
      startAt: startAt,
    );
  }
}

class _Clock extends ChangeNotifier implements BarClock {
  @override
  Duration barLength = const Duration(seconds: 2);

  @override
  double? barPhase;

  @override
  int bpm = 120;

  @override
  TimeSignature signature = TimeSignature.fourFour;

  /// Tells the listeners that the tempo or the time signature changed.
  void announce() => notifyListeners();
}
