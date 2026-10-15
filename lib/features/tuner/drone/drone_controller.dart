import 'package:flutter/foundation.dart';

import '../../../audio/pitch.dart';
import '../../../audio/tone_output.dart';

/// What the drone plays on its note: the note alone, or a chord built on it.
enum DroneVoicing { root, chord }

enum ChordType {
  major([1, 5 / 4, 3 / 2]),
  minor([1, 6 / 5, 3 / 2]),
  seventh([1, 5 / 4, 3 / 2, 7 / 4]);

  const ChordType(this.ratios);

  /// Pure (just) ratios to the root: they do not beat against each other,
  /// which is what you want when checking intonation.
  final List<double> ratios;
}

/// State and playback of the drone: a sustained pure tone to practise on.
class DroneController extends ChangeNotifier {
  DroneController(this._output);

  final ToneOutput _output;

  /// The drone always plays in the middle octave (A4 = 440 Hz): high enough
  /// for any phone speaker, and easy to hear against a bass.
  static const octave = 4;

  /// Fixed: the phone's volume buttons set how loud it is.
  static const _volume = 0.8;

  bool _playing = false;
  bool _audioFailed = false;
  Note _note = const Note(9, octave);
  DroneVoicing _voicing = DroneVoicing.root;
  ChordType _chord = ChordType.major;
  double _a4 = 440;

  bool get isPlaying => _playing;

  /// True when the last attempt to start sound failed on this device.
  bool get audioFailed => _audioFailed;
  Note get note => _note;
  DroneVoicing get voicing => _voicing;
  ChordType get chord => _chord;
  double get a4 => _a4;

  /// Frequency of the root note, in Hz.
  double get frequency => _note.frequency(a4: _a4);

  /// Frequencies currently sounding: the root, then the rest of the chord.
  List<double> get frequencies => [
    for (final ratio in _voicing == DroneVoicing.root ? [1.0] : _chord.ratios)
      frequency * ratio,
  ];

  /// The root a little louder than the notes above it.
  List<double> get _gains => [
    for (var i = 0; i < frequencies.length; i++) i == 0 ? 1.0 : 0.7,
  ];

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

  /// What a note key does: plays [pitchClass], switches to it if another
  /// note is playing, or stops it if it is the one already playing.
  Future<void> tapNote(int pitchClass) {
    if (_playing && _note.pitchClass == pitchClass) return stop();
    setPitchClass(pitchClass);
    return _playing ? Future.value() : start();
  }

  void setPitchClass(int pitchClass) =>
      _update(() => _note = Note(pitchClass, octave));

  void setVoicing(DroneVoicing voicing) => _update(() => _voicing = voicing);

  void setChord(ChordType chord) => _update(() => _chord = chord);

  void setReferencePitch(double a4) => _update(() => _a4 = a4);

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
