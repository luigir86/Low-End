import 'package:flutter/foundation.dart';

import '../../../audio/pitch.dart';
import '../../../audio/tone_output.dart';

/// What the drone plays on its note: the note alone, or a chord built on it.
enum DroneVoicing { root, chord }

enum ChordType {
  major([1, 5 / 4, 3 / 2]),
  minor([1, 6 / 5, 3 / 2]),
  seventh([1, 5 / 4, 3 / 2, 16 / 9]);

  const ChordType(this.ratios);

  /// Pure (just) ratios to the root: they do not beat against each other,
  /// which is what you want when checking intonation. The seventh is 16/9
  /// (996 cents), the pure ratio closest to the minor seventh a bassist
  /// plays: the harmonic seventh, 7/4, would sound 31 cents flat of it.
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
  var _disposed = false;

  /// The latest sound change still under way, if any (see [_sync]).
  Future<void>? _pending;

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

  Future<void> start() {
    _playing = true;
    _audioFailed = false;
    _notify();
    return _sync();
  }

  Future<void> stop() {
    _playing = false;
    _notify();
    return _sync();
  }

  Future<void> toggle() => _playing ? stop() : start();

  /// What a note key does: plays [pitchClass], switches to it if another
  /// note is playing, or stops it if it is the one already playing.
  Future<void> tapNote(int pitchClass) {
    if (_playing && _note.pitchClass == pitchClass) return stop();
    setPitchClass(pitchClass);
    return _playing ? Future.value() : start();
  }

  void setPitchClass(int pitchClass) {
    if (pitchClass == _note.pitchClass) return;
    _update(() => _note = Note(pitchClass, octave));
  }

  void setVoicing(DroneVoicing voicing) {
    if (voicing == _voicing) return;
    _update(() => _voicing = voicing);
  }

  void setChord(ChordType chord) {
    if (chord == _chord) return;
    _update(() => _chord = chord);
  }

  void setReferencePitch(double a4) {
    if (a4 == _a4) return;
    _update(() => _a4 = a4);
  }

  void _update(VoidCallback change) {
    change();
    _notify();
    if (_playing) _sync();
  }

  /// Brings the sound in line with [isPlaying] and the current settings.
  ///
  /// Starts and retunes run one after the other, each reading the state
  /// when its turn comes, so two quick changes never mix their voices; the
  /// first one starts at once, so sound begins without delay. Stopping
  /// happens at once too, and a start still under way stops again as soon
  /// as it is done, so a stop pressed while the audio engine is starting
  /// really silences it. Never throws: a failure shows in [audioFailed].
  Future<void> _sync() {
    if (!_playing || _disposed) return _silence();
    final previous = _pending;
    late final Future<void> done;
    done = (previous == null ? _play() : previous.then((_) => _play()))
        .whenComplete(() {
          if (identical(_pending, done)) _pending = null;
        });
    return _pending = done;
  }

  Future<void> _play() async {
    if (!_playing || _disposed) return;
    try {
      await _output.play(frequencies, _gains, _volume);
    } catch (error) {
      debugPrint('Drone could not start: $error');
      _playing = false;
      _audioFailed = true;
      _notify();
    }
    // Stopped (or failed) while starting: voices that only started now
    // must not keep sounding unseen.
    if (!_playing || _disposed) await _silence();
  }

  Future<void> _silence() async {
    try {
      await _output.stop();
    } catch (error) {
      debugPrint('Drone could not stop: $error');
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _playing = false;
    _sync();
    super.dispose();
  }
}
