import 'package:flutter/foundation.dart';

import '../../../audio/pitch.dart';
import '../../../audio/tone_output.dart';

/// State and playback of the drone: a sustained pure tone to practise on.
class DroneController extends ChangeNotifier {
  DroneController(this._output);

  final ToneOutput _output;

  /// Lowest and highest octave offered. Octave 1 holds the double bass
  /// open strings E1 and A1.
  static const minOctave = 1;
  static const maxOctave = 5;

  /// Octaves at or below this are too low for most phone speakers.
  static const lowOctaveWarning = 2;

  bool _playing = false;
  bool _audioFailed = false;
  Note _note = const Note(9, 3); // A3, 220 Hz at A4 = 440.
  bool _addFifth = false;
  bool _addOctave = false;
  double _a4 = 440;
  double _volume = 0.7;

  bool get isPlaying => _playing;

  /// True when the last attempt to start sound failed on this device.
  bool get audioFailed => _audioFailed;
  Note get note => _note;
  bool get addFifth => _addFifth;
  bool get addOctave => _addOctave;
  double get a4 => _a4;
  double get volume => _volume;
  bool get isBelowSpeakerRange => _note.octave <= lowOctaveWarning;

  /// Frequency of the main note, in Hz.
  double get frequency => _note.frequency(a4: _a4);

  /// Frequencies currently sounding: the note, then the optional fifth and
  /// octave. They use pure ratios (3:2 and 2:1) so they do not beat against
  /// the note, which is what you want when checking intonation.
  List<double> get frequencies => [
    frequency,
    if (_addFifth) frequency * 3 / 2,
    if (_addOctave) frequency * 2,
  ];

  List<double> get _gains => [1, if (_addFifth) 0.7, if (_addOctave) 0.6];

  Future<void> start() async {
    _playing = true;
    _audioFailed = false;
    notifyListeners();
    try {
      await _output.play(frequencies, _gains, _volume);
    } catch (error) {
      debugPrint('Drone could not start: $error');
      _playing = false;
      _audioFailed = true;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _playing = false;
    notifyListeners();
    await _output.stop();
  }

  Future<void> toggle() => _playing ? stop() : start();

  void setPitchClass(int pitchClass) =>
      _update(() => _note = Note(pitchClass, _note.octave));

  void setOctave(int octave) => _update(
    () => _note = Note(_note.pitchClass, octave.clamp(minOctave, maxOctave)),
  );

  void setAddFifth(bool value) => _update(() => _addFifth = value);

  void setAddOctave(bool value) => _update(() => _addOctave = value);

  void setReferencePitch(double a4) => _update(() => _a4 = a4);

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    notifyListeners();
    if (_playing) _output.setVolume(_volume);
  }

  void _update(VoidCallback change) {
    change();
    notifyListeners();
    if (_playing) _output.play(frequencies, _gains, _volume);
  }

  @override
  void dispose() {
    _output.stop();
    super.dispose();
  }
}
