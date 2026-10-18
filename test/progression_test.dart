import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/features/metronome/time_signature.dart';
import 'package:low_end/audio/pitch.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/features/tuner/drone/drone_controller.dart';
import 'package:low_end/features/tuner/drone/harmony.dart';

/// A bar clock set by hand, as the metronome would be.
class _Clock extends ChangeNotifier implements BarClock {
  @override
  Duration barLength = const Duration(seconds: 2);

  @override
  double? barPhase;

  @override
  int bpm = 120;

  @override
  TimeSignature signature = TimeSignature.fourFour;
}

/// The frequencies sounding, each to a millionth of a hertz.
Matcher _sounds(List<double> hz) => pairwiseCompare<double, double>(
  hz,
  (a, b) => (a - b).abs() < 1e-6,
  'within 1e-6 Hz of',
);

double _hz(int pitchClass) =>
    Note(pitchClass, DroneController.defaultOctave).frequency();

void main() {
  late SilentToneOutput output;
  late _Clock clock;
  late DroneController drone;

  setUp(() {
    output = SilentToneOutput();
    clock = _Clock();
    drone = DroneController(output, clock: clock);
  });

  // testWidgets for its fake clock: the bar timers run without waiting.
  testWidgets('II–V–I in C plays D minor, G7, C, one chord a bar', (
    tester,
  ) async {
    drone.setVoicing(DroneVoicing.progression);
    await drone.tapNote(0); // C
    await tester.pump();
    expect(drone.currentChord?.root, 2);
    expect(
      output.frequencies,
      _sounds([_hz(2), _hz(2) * 6 / 5, _hz(2) * 3 / 2]),
    );
    expect(drone.chordTones, {5, 9}); // F and A
    // The numerals stay on their notes while it plays.
    expect(drone.degreeLabels, {2: 'II', 7: 'V', 0: 'I'});
    // Every chord is made ready at the start.
    expect(output.prepared, hasLength(3));

    await tester.pump(const Duration(seconds: 2));
    expect(drone.step, 1);
    expect(output.frequencies.first, closeTo(_hz(7), 1e-9)); // G
    // The dominant always has its seventh, as in Chord mode.
    final g = _hz(7);
    expect(output.frequencies, _sounds([g, g * 5 / 4, g * 3 / 2, g * 16 / 9]));

    await tester.pump(const Duration(seconds: 2));
    expect(drone.step, 2);
    expect(output.frequencies.first, closeTo(_hz(0), 1e-9)); // C

    // And round again.
    await tester.pump(const Duration(seconds: 2));
    expect(drone.step, 0);
    await drone.stop();
  });

  testWidgets('with sevenths: Dm7, G7, Cmaj7', (tester) async {
    drone
      ..setVoicing(DroneVoicing.progression)
      ..setSevenths(true);
    await drone.tapNote(0);
    await tester.pump();
    final d = _hz(2);
    expect(output.frequencies, _sounds([d, d * 6 / 5, d * 3 / 2, d * 9 / 5]));
    await tester.pump(const Duration(seconds: 2));
    final g = _hz(7);
    expect(output.frequencies, _sounds([g, g * 5 / 4, g * 3 / 2, g * 16 / 9]));
    await tester.pump(const Duration(seconds: 2));
    final c = _hz(0);
    expect(output.frequencies, _sounds([c, c * 5 / 4, c * 3 / 2, c * 15 / 8]));
    await drone.stop();
  });

  testWidgets('changes chord on the metronome\'s "one"', (tester) async {
    clock.barPhase = 0.75; // A quarter of the bar still to go.
    drone.setVoicing(DroneVoicing.progression);
    await drone.tapNote(0);
    await tester.pump(const Duration(milliseconds: 400));
    expect(drone.step, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(drone.step, 1, reason: 'half a second, then the bar line');
    await drone.stop();
  });

  testWidgets('a new key or progression starts again from its first chord', (
    tester,
  ) async {
    drone.setVoicing(DroneVoicing.progression);
    await drone.tapNote(0);
    await tester.pump(const Duration(seconds: 2));
    expect(drone.step, 1);
    drone.setPitchClass(7); // G: II is A minor.
    await tester.pump();
    expect(drone.step, 0);
    expect(drone.currentChord?.root, 9);
    drone.setProgression(Progression.blues);
    expect(drone.step, 0);
    expect(drone.progression.steps, hasLength(12));
    await drone.stop();
  });

  test('chords take the seventh too, and the 7 chord always has it', () async {
    drone.setVoicing(DroneVoicing.chord);
    await drone.start();
    expect(output.frequencies, hasLength(3));
    drone.setSevenths(true);
    await pumpEventQueue();
    final a = _hz(9);
    expect(output.frequencies, _sounds([a, a * 5 / 4, a * 3 / 2, a * 15 / 8]));
    drone
      ..setSevenths(false)
      ..setChord(ChordType.seventh);
    await pumpEventQueue();
    expect(output.frequencies, hasLength(4));
    await drone.stop();
  });

  test('the blues is all dominant sevenths, with "7" off too', () async {
    drone
      ..setVoicing(DroneVoicing.progression)
      ..setProgression(Progression.blues)
      ..setPitchClass(0);
    expect(drone.sevenths, isFalse);
    expect(Progression.blues.steps.map((s) => s.quality).toSet(), {
      ChordQuality.dominant,
    });
    expect(drone.currentChord?.seventh, isTrue);
    await drone.start();
    final c = _hz(0);
    expect(output.frequencies, _sounds([c, c * 5 / 4, c * 3 / 2, c * 16 / 9]));
    await drone.stop();
  });

  test('"7" off leaves the other chords of a progression as triads', () {
    drone
      ..setVoicing(DroneVoicing.progression)
      ..setPitchClass(0);
    // II–V–I: Dm, G7, C.
    expect(drone.currentChord, (
      root: 2,
      quality: ChordQuality.minor,
      seventh: false,
    ));
    drone.setProgression(Progression.oneFourFive);
    expect(drone.currentChord?.seventh, isFalse);
  });

  group('chords are spelled as in their key', () {
    List<String> names(DroneController d, int key, Progression p) {
      d
        ..setVoicing(DroneVoicing.progression)
        ..setProgression(p)
        ..setPitchClass(key);
      return [
        for (var i = 0; i < p.steps.length; i++)
          spell(
            (key + p.steps[i].offset) % 12,
            d.letterAt(i),
            NoteNames.letters,
          ),
      ];
    }

    test('minor II–V–I in C♯ and F♯ minor', () {
      expect(names(drone, 1, Progression.minorTwoFiveOne), ['D♯', 'G♯', 'C♯']);
      expect(names(drone, 6, Progression.minorTwoFiveOne), ['G♯', 'C♯', 'F♯']);
    });

    test('I–VI–IV–V in F♯ has D♯ minor, not E♭', () {
      expect(names(drone, 6, Progression.oneSixFourFive), [
        'F♯',
        'D♯',
        'B',
        'C♯',
      ]);
    });

    test('the flat keys keep their flats', () {
      expect(names(drone, 10, Progression.twoFiveOne), ['C', 'F', 'B♭']);
      expect(names(drone, 3, Progression.oneFourFive), ['E♭', 'A♭', 'B♭']);
    });

    test('C♯ can be written D♭, and its chords follow: G♭, A♭', () {
      expect(drone.spelledFlat(1), isFalse);
      drone.toggleSpelling(1);
      expect(drone.spelledFlat(1), isTrue);
      expect(names(drone, 1, Progression.oneFourFive), ['D♭', 'G♭', 'A♭']);
      drone.toggleSpelling(6);
      expect(names(drone, 6, Progression.twoFiveOne), ['A♭', 'D♭', 'G♭']);
      // In solfège too.
      expect(spell(6, drone.keyLetter, NoteNames.solfege), 'Sol♭');
      // Only C♯/D♭ and F♯/G♭ change: E♭ stays E♭.
      drone.toggleSpelling(3);
      expect(drone.spelledFlat(3), isFalse);
      drone.toggleSpelling(1);
      drone.setPitchClass(1);
      expect(spell(1, drone.keyLetter, NoteNames.letters), 'C♯');
    });
  });

  test('minor II–V–I has a diminished II', () {
    final steps = Progression.minorTwoFiveOne.steps;
    expect(steps.first.quality, ChordQuality.halfDiminished);
    expect(ChordQuality.halfDiminished.semitones(seventh: false), [3, 6]);
    expect(steps.last.quality, ChordQuality.minor);
  });
}
