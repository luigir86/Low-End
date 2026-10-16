import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/click_sound.dart';
import 'package:low_end/audio/piano_output.dart';
import 'package:low_end/audio/piano_sound.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/features/metronome/time_signature.dart';
import 'package:low_end/features/tuner/drone/drone_controller.dart';

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
        [60, 64, 67],
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
      drone.setChord(ChordType.seventh);
      drone.setStyle(DroneStyle.arpeggio);
      await drone.tapNote(7); // G
      expect(piano.chords!.single, [67, 71, 74, 77]);
      expect(piano.style, PianoStyle.arpeggio);
    });

    test('a progression is one chord a bar, as a loop', () async {
      drone.setVoicing(DroneVoicing.progression);
      drone.setStyle(DroneStyle.beat);
      await drone.tapNote(0);
      // II–V–I in C: D minor, G, C.
      expect(piano.chords, [
        [62, 65, 69],
        [67, 71, 74],
        [60, 64, 67],
      ]);
    });

    test("a single note is played by the piano too", () async {
      await drone.tapNote(9); // A
      expect(piano.chords, [
        [69],
      ]);
      // Kept sounding, not struck on every beat, whatever the style.
      expect(piano.style, PianoStyle.drone);
      expect(tone.frequencies, isEmpty);
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
      expect(piano.chords!.single.first, 62);
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
