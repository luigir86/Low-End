import '../../metronome/metronome_controller.dart';
import '../../metronome/time_signature.dart';
import 'drone_controller.dart';
import 'harmony.dart';

/// Sets the key, the progression and the tempo of [song]: what touching it
/// in the list of example songs does, and the `song` of the actions.
void applySong(
  ExampleSong song, {
  required DroneController drone,
  required MetronomeController metronome,
}) {
  drone
    ..setPitchClass(song.pitchClass)
    ..setProgression(song.progression)
    ..setVoicing(DroneVoicing.progression);
  metronome
    ..setSignature(TimeSignature.fourFour)
    ..setBpm(song.bpm);
}
