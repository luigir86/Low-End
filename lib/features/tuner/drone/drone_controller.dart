import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../audio/pitch.dart';
import '../../../audio/tone_output.dart';
import 'harmony.dart';

/// What the drone plays on its note: the note alone, a chord built on it,
/// or a progression in its key.
enum DroneVoicing { root, chord, progression }

/// The chords offered in Chord mode.
enum ChordType {
  major(ChordQuality.major),
  minor(ChordQuality.minor),

  /// The dominant seventh: always with its seventh, which names it.
  seventh(ChordQuality.dominant);

  const ChordType(this.quality);

  final ChordQuality quality;
}

/// The length and position of the bar a progression follows: the
/// metronome's, so chords change on its "one".
abstract interface class BarClock {
  Duration get barLength;

  /// How far into the bar it is, 0 to 1, or null when not counting.
  double? get barPhase;
}

/// 4/4 at 80 BPM, for when nothing else keeps time.
class _FixedBar implements BarClock {
  const _FixedBar();

  @override
  Duration get barLength => const Duration(seconds: 3);

  @override
  double? get barPhase => null;
}

/// A chord as the drone plays it.
typedef DroneChord = ({int root, ChordQuality quality, bool seventh});

/// State and playback of the drone: a sustained tone to practise on.
class DroneController extends ChangeNotifier {
  DroneController(this._output, {BarClock? clock})
    : _clock = clock ?? const _FixedBar();

  final ToneOutput _output;
  final BarClock _clock;

  /// The drone always plays in the middle octave (A4 = 440 Hz): high enough
  /// for any phone speaker, and easy to hear against a bass.
  static const octave = 4;

  /// Loudness at full level.
  static const _fullVolume = 0.8;

  /// Set by the metronome / drone balance; the phone's volume buttons set
  /// how loud it all is.
  double _level = 1;

  double get _volume => _fullVolume * _level;

  bool _playing = false;
  bool _audioFailed = false;
  Note _note = const Note(9, octave);
  DroneVoicing _voicing = DroneVoicing.root;
  ChordType _chord = ChordType.major;
  Progression _progression = Progression.twoFiveOne;
  bool _sevenths = false;
  int _step = 0;
  Timer? _barTimer;
  double _a4 = 440;
  var _disposed = false;

  /// The latest sound change still under way, if any (see [_sync]).
  Future<void>? _pending;

  bool get isPlaying => _playing;

  /// True when the last attempt to start sound failed on this device.
  bool get audioFailed => _audioFailed;

  /// The note touched: the root, or the key of a progression.
  Note get note => _note;
  DroneVoicing get voicing => _voicing;
  ChordType get chord => _chord;
  Progression get progression => _progression;

  /// Whether chords and progressions add the seventh to their triads.
  bool get sevenths => _sevenths;

  /// The chord of the progression playing now, 0 for the first.
  int get step => _step;
  double get a4 => _a4;

  /// The chord sounding (or that would sound), or null for the note alone.
  DroneChord? get currentChord => _chordAt(_step);

  /// The next chord of the progression, or null outside a progression.
  DroneChord? get nextChord => _voicing == DroneVoicing.progression
      ? _chordAt((_step + 1) % _progression.steps.length)
      : null;

  DroneChord? _chordAt(int step) => switch (_voicing) {
    DroneVoicing.root => null,
    DroneVoicing.chord => (
      root: _note.pitchClass,
      quality: _chord.quality,
      seventh: _sevenths || _chord == ChordType.seventh,
    ),
    DroneVoicing.progression => (
      root: (_note.pitchClass + _progression.steps[step].offset) % 12,
      quality: _progression.steps[step].quality,
      seventh: _sevenths,
    ),
  };

  /// The root sounding now: the note, or the root of the current chord.
  int get rootPitchClass => currentChord?.root ?? _note.pitchClass;

  /// Frequency of the root sounding, in Hz.
  double get frequency => Note(rootPitchClass, octave).frequency(a4: _a4);

  /// The pitch classes of the other notes of the chord sounding.
  Set<int> get chordTones {
    final c = currentChord;
    if (c == null) return const {};
    return {
      for (final s in c.quality.semitones(seventh: c.seventh))
        (c.root + s) % 12,
    };
  }

  /// Frequencies currently sounding: the root, then the rest of the chord.
  List<double> get frequencies => _frequenciesOf(currentChord);

  List<double> _frequenciesOf(DroneChord? c) {
    final root = Note(c?.root ?? _note.pitchClass, octave).frequency(a4: _a4);
    final ratios = c == null ? [1.0] : c.quality.ratios(seventh: c.seventh);
    return [for (final r in ratios) root * r];
  }

  /// The root a little louder than the notes above it.
  static List<double> _gainsFor(int voices) => [
    for (var i = 0; i < voices; i++) i == 0 ? 1.0 : 0.7,
  ];

  Future<void> start() {
    _playing = true;
    _audioFailed = false;
    _step = 0;
    _notify();
    _prepareProgression();
    _scheduleBar();
    return _sync();
  }

  Future<void> stop() {
    _playing = false;
    _barTimer?.cancel();
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
    _update(() => _note = Note(pitchClass, octave), restart: true);
  }

  void setVoicing(DroneVoicing voicing) {
    if (voicing == _voicing) return;
    _update(() => _voicing = voicing, restart: true);
  }

  void setChord(ChordType chord) {
    if (chord == _chord) return;
    _update(() => _chord = chord);
  }

  void setProgression(Progression progression) {
    if (progression == _progression) return;
    _update(() => _progression = progression, restart: true);
  }

  void setSevenths(bool sevenths) {
    if (sevenths == _sevenths) return;
    _update(() => _sevenths = sevenths);
  }

  /// Sets the level from the metronome / drone balance, 0 to 1.
  void setLevel(double level) {
    final value = level.clamp(0.0, 1.0);
    if (value == _level) return;
    _level = value;
    if (_playing && !_disposed) {
      try {
        _output.setVolume(_volume);
      } catch (error) {
        debugPrint('Drone level could not change: $error');
      }
    }
  }

  void setReferencePitch(double a4) {
    if (a4 == _a4) return;
    _update(() => _a4 = a4);
  }

  /// Applies [change]; with [restart], a progression starts again from its
  /// first chord.
  void _update(VoidCallback change, {bool restart = false}) {
    change();
    if (restart) _step = 0;
    _notify();
    if (!_playing) return;
    _prepareProgression();
    if (restart) _scheduleBar();
    _sync();
  }

  /// Gets every chord of the progression ready, so each change of chord
  /// sounds on time.
  void _prepareProgression() {
    if (_voicing != DroneVoicing.progression) return;
    final chords = [
      for (var i = 0; i < _progression.steps.length; i++)
        _frequenciesOf(_chordAt(i)),
    ];
    _output
        .prepare([for (final f in chords) (f, _gainsFor(f.length))])
        .catchError((Object error) {
          debugPrint('Drone could not prepare the progression: $error');
        });
  }

  /// Moves to the next chord at the next bar line: the metronome's "one"
  /// when it is counting, otherwise a bar of its tempo from now.
  void _scheduleBar() {
    _barTimer?.cancel();
    if (!_playing || _voicing != DroneVoicing.progression) return;
    final bar = _clock.barLength;
    final phase = _clock.barPhase;
    var wait = phase == null ? bar : bar * (1 - phase);
    // Just after a bar line, wait for the next one rather than cut short
    // the chord that has only just started.
    if (wait < const Duration(milliseconds: 150)) wait += bar;
    _barTimer = Timer(wait, () {
      if (!_playing || _disposed) return;
      _step = (_step + 1) % _progression.steps.length;
      _notify();
      _sync();
      _scheduleBar();
    });
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
      final f = frequencies;
      await _output.play(f, _gainsFor(f.length), _volume);
    } catch (error) {
      debugPrint('Drone could not start: $error');
      _playing = false;
      _audioFailed = true;
      _barTimer?.cancel();
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
    _barTimer?.cancel();
    _sync();
    super.dispose();
  }
}
