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

  test('plays the selected note and stops', () async {
    drone.setPitchClass(2); // D
    drone.setOctave(2);
    await drone.start();
    expect(drone.isPlaying, isTrue);
    expect(output.frequencies.single, closeTo(73.42, 0.01));

    await drone.stop();
    expect(drone.isPlaying, isFalse);
    expect(output.frequencies, isEmpty);
  });

  test('adds a pure fifth and the octave above', () async {
    drone.setAddFifth(true);
    drone.setAddOctave(true);
    await drone.start();
    final root = drone.frequency;
    expect(output.frequencies, [root, root * 1.5, root * 2]);
  });

  test('retunes while playing when the reference pitch changes', () async {
    await drone.start();
    drone.setReferencePitch(442);
    expect(output.frequencies.single, closeTo(221, 0.001)); // A3 at 442
  });

  test('keeps the octave in range and flags notes too low for speakers', () {
    drone.setOctave(0);
    expect(drone.note.octave, DroneController.minOctave);
    expect(drone.isBelowSpeakerRange, isTrue);
    drone.setOctave(9);
    expect(drone.note.octave, DroneController.maxOctave);
    expect(drone.isBelowSpeakerRange, isFalse);
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
