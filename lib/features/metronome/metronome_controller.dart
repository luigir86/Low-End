import 'package:flutter/foundation.dart';

import '../../audio/click_output.dart';
import '../../audio/click_sound.dart';

/// State and playback of the metronome, in 4/4.
class MetronomeController extends ChangeNotifier {
  MetronomeController(this._output, {Stopwatch? clock})
    : _clock = clock ?? Stopwatch();

  final ClickOutput _output;

  /// Measures time for the beat shown on screen (the sound keeps its own
  /// perfect time in the audio engine).
  final Stopwatch _clock;

  static const minBpm = 30;
  static const maxBpm = 250;
  static const startBpm = 80;
  static const beatsPerBar = 4;

  /// Taps further apart than this start a new count.
  static const _tapTimeout = Duration(seconds: 2);

  /// Intervals averaged by [tap]: enough to smooth a hand, few enough to
  /// follow a change.
  static const _tapsKept = 4;

  int _bpm = startBpm;
  bool _playing = false;
  bool _audioFailed = false;
  var _disposed = false;

  // Where in the bar the screen's clock started, see [barPhase].
  Duration _startedAt = Duration.zero;

  final _taps = <Duration>[];

  bool _syncing = false;
  bool _syncAgain = false;

  int get bpm => _bpm;
  bool get isPlaying => _playing;

  /// True when the last attempt to start sound failed on this device.
  bool get audioFailed => _audioFailed;

  Duration get beatLength => Duration(microseconds: 60000000 ~/ _bpm);
  Duration get barLength => beatLength * beatsPerBar;

  /// How far into the bar the metronome is, from 0 to just under 1, or null
  /// when stopped.
  double? get barPhase {
    if (!_playing) return null;
    final at = _startedAt + _clock.elapsed;
    return at.inMicroseconds / barLength.inMicroseconds % 1;
  }

  /// The beat now sounding, 0 (the "one") to 3, or null when stopped.
  int? get beat {
    final phase = barPhase;
    return phase == null ? null : (phase * beatsPerBar).floor();
  }

  /// Time since the current beat sounded, or null when stopped.
  Duration? get sinceBeat {
    final phase = barPhase;
    if (phase == null) return null;
    final inBeat = phase * beatsPerBar % 1;
    return beatLength * inBeat;
  }

  Future<void> start() {
    if (_playing) return Future.value();
    _playing = true;
    _audioFailed = false;
    _restartClock(Duration.zero);
    _notify();
    return _sync();
  }

  Future<void> stop() {
    if (!_playing) return Future.value();
    _playing = false;
    _clock.stop();
    _notify();
    return _sync();
  }

  Future<void> toggle() => _playing ? stop() : start();

  /// Sets the tempo, kept within [minBpm] and [maxBpm]. While playing, the
  /// beat carries on from where it was.
  void setBpm(int bpm) {
    final value = bpm.clamp(minBpm, maxBpm);
    if (value == _bpm) return;
    final phase = barPhase;
    _bpm = value;
    if (phase != null) _restartClock(barLength * phase);
    _notify();
    if (_playing) _sync();
  }

  /// Moves the tempo up or down by [delta] BPM.
  void step(int delta) => setBpm(_bpm + delta);

  /// One tap of the TAP button: after two taps or more, sets the tempo to
  /// the average of the latest intervals.
  void tap(Duration now) {
    if (_taps.isNotEmpty && now - _taps.last > _tapTimeout) _taps.clear();
    _taps.add(now);
    if (_taps.length > _tapsKept + 1) _taps.removeAt(0);
    if (_taps.length < 2) return;
    final span = _taps.last - _taps.first;
    final interval = span.inMicroseconds / (_taps.length - 1);
    setBpm((60000000 / interval).round());
  }

  void _restartClock(Duration at) {
    _startedAt = at;
    _clock
      ..reset()
      ..start();
  }

  /// Brings the sound in line with [isPlaying] and [bpm], one call at a
  /// time; changes made meanwhile are applied right after, all at once, so
  /// holding + only rebuilds the bar as often as the engine can follow.
  Future<void> _sync() async {
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncAgain = false;
        await _apply();
      } while (_syncAgain && !_disposed);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _apply() async {
    try {
      if (!_playing || _disposed) {
        await _output.stop();
        return;
      }
      final at = barLength * (barPhase ?? 0);
      await _output.play(ClickSound.bar(bpm: _bpm), at);
      // The sound starts now: line the screen up with it.
      _restartClock(at);
    } catch (error) {
      debugPrint('Metronome could not start: $error');
      _playing = false;
      _audioFailed = true;
      _clock.stop();
      _notify();
      try {
        await _output.stop();
      } catch (_) {}
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
