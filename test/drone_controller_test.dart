import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/features/tuner/drone/drone_controller.dart';

void main() {
  late SilentToneOutput output;
  late DroneController drone;

  setUp(() {
    output = SilentToneOutput();
    drone = DroneController(output);
  });

  test('a note key plays, switches and stops', () async {
    await drone.tapNote(2); // D
    expect(drone.isPlaying, isTrue);
    // Always the middle octave: D4.
    expect(output.frequencies.single, closeTo(293.66, 0.01));

    await drone.tapNote(9); // Another key switches to A4.
    expect(drone.isPlaying, isTrue);
    expect(output.frequencies.single, closeTo(440, 0.01));

    await drone.tapNote(9); // The lit key again stops it.
    expect(drone.isPlaying, isFalse);
    expect(output.frequencies, isEmpty);
  });

  test('plays chords in pure intervals', () async {
    drone.setVoicing(DroneVoicing.chord);
    await drone.start();
    final root = drone.frequency;
    expect(output.frequencies, [root, root * 5 / 4, root * 3 / 2]);

    drone.setChord(ChordType.minor);
    await _settle();
    expect(output.frequencies, [root, root * 6 / 5, root * 3 / 2]);

    drone.setChord(ChordType.seventh);
    await _settle();
    expect(output.frequencies, [
      root,
      root * 5 / 4,
      root * 3 / 2,
      root * 16 / 9,
    ]);

    drone.setVoicing(DroneVoicing.root);
    await _settle();
    expect(output.frequencies, [root]);
  });

  test('retunes while playing when the reference pitch changes', () async {
    await drone.start();
    drone.setReferencePitch(442);
    await _settle();
    expect(output.frequencies.single, closeTo(442, 0.001)); // A4 at 442
  });

  test('names the other notes of the chord', () {
    drone.setPitchClass(9); // A
    expect(drone.chordTones, isEmpty, reason: 'root only');
    drone.setVoicing(DroneVoicing.chord);
    expect(drone.chordTones, {1, 4}); // C# and E
    drone.setChord(ChordType.minor);
    expect(drone.chordTones, {0, 4}); // C and E
    drone.setChord(ChordType.seventh);
    expect(drone.chordTones, {1, 4, 7}); // C#, E and G
  });

  test('reports when audio cannot start', () async {
    final failing = DroneController(_FailingOutput());
    await failing.start();
    expect(failing.isPlaying, isFalse);
    expect(failing.audioFailed, isTrue);
  });
}

class _FailingOutput extends SilentToneOutput {
  @override
  Future<void> play(List<double> f, List<double> gains, double v) =>
      Future.error(StateError('no audio device'));
}

/// Lets queued sound changes reach the output: the controller applies them
/// one after the other (see DroneController._sync).
Future<void> _settle() => Future<void>.delayed(Duration.zero);
