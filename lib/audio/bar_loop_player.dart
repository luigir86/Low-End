import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'loop_transport.dart';
import 'soloud_engine.dart';

/// Plays one looping recording of whole bars with the SoLoud engine: the
/// metronome's clicks, or the piano's chords. Two of them (see [name])
/// keep together through the [LoopTransport].
///
/// Calls are expected one at a time (the controllers wait for each one to
/// finish before the next).
class BarLoopPlayer {
  BarLoopPlayer(
    this.name, {
    this.follows = false,
    this.crossfade = Duration.zero,
  });

  /// 'click' or 'piano': how the other loop knows this one.
  final String name;

  /// True when this loop keeps to the other's beat after a change of
  /// tempo, rather than carrying on from its own place: the piano, which
  /// takes a moment to get ready, follows the clicks, which change at once.
  final bool follows;

  /// How long a loop replacing another fades in over it when it carries on
  /// (a change of tempo): the piano's ringing notes then pass from one to
  /// the other without a jump. Zero for the clicks, which are short.
  final Duration crossfade;

  AudioSource? _source;
  SoundHandle? _handle;
  Duration _length = Duration.zero;
  Duration _bar = Duration.zero;
  double _volume = 1;

  SoLoud get _soloud => SoLoud.instance;

  bool get isPlaying => _handle != null;

  /// Loops [wav], whose bars last [bar] (the loop is a whole number of
  /// them), replacing the loop already playing, if any.
  ///
  /// With no [startAt], a loop replacing another carries on from where the
  /// old one is, scaled to its own length, as a tempo change should; one
  /// that [follows] picks up at the other loop's place in the bar, if it is
  /// playing. With a [startAt] (or when nothing was playing), it starts
  /// that far in; if the other loop is playing it then waits for that
  /// loop's next bar line, so that the two stay together. Says where and
  /// when it began.
  ///
  /// [preRoll], for a loop that starts on its own, is that much of the end
  /// of the loop, which must be silent, played first: the output comes up
  /// during it, and the first sound is not softened. It counts in the
  /// delay.
  ///
  /// [tailFor], when a new loop replaces one from its start, gives what the
  /// old loop sounds like let go at a place in it (see [stop]); it plays
  /// from the moment the old one stops.
  Future<LoopStart> play(
    Uint8List wav,
    Duration bar, {
    Duration? startAt,
    Duration preRoll = Duration.zero,
    Uint8List Function(Duration position)? tailFor,
  }) async {
    await ensureSoLoud();
    final source = await _soloud.loadMem('$name-loop.wav', wav);
    final length = _soloud.getLength(source);
    final old = _handle != null && _soloud.getIsValidVoiceHandle(_handle!)
        ? _handle
        : null;
    final oldSource = _source;
    final carryOn = startAt == null && old != null;
    final wait = carryOn ? null : LoopTransport.instance.untilBarLine(name);
    // The moment [wait] counts from, and where the old loop was then.
    final waitedFrom = _soloud.getEngineTime();
    final oldThen = old == null ? null : _soloud.getPosition(old);
    final since = Stopwatch()..start();
    var position = startAt ?? Duration.zero;
    var delay = Duration.zero;
    if (carryOn) {
      final was = Duration(
        microseconds:
            _soloud.getPosition(old).inMicroseconds % _length.inMicroseconds,
      );
      final leader = follows ? LoopTransport.instance.phaseOf(name) : null;
      if (leader != null && _bar > Duration.zero) {
        // Back on the other loop's beat: the old loop went on at the old
        // tempo while the new one was made, and drifted from it.
        position = LoopTransport.followerPosition(
          oldPosition: was,
          oldBar: _bar,
          bar: bar,
          bars: math.max(
            1,
            (length.inMicroseconds / bar.inMicroseconds).round(),
          ),
          leaderPhase: leader,
        );
      } else {
        // The old loop's place, as a fraction of its length.
        position = Duration(
          microseconds:
              (was.inMicroseconds *
                      length.inMicroseconds /
                      _length.inMicroseconds)
                  .round(),
        );
      }
    }
    // The silence before the first sound of a loop that starts by itself.
    var seekTo = position;
    if (wait == null &&
        !carryOn &&
        position == Duration.zero &&
        preRoll > Duration.zero &&
        preRoll < length) {
      seekTo = length - preRoll;
      delay = preRoll;
    }
    final SoundHandle handle;
    Duration? startsAt;
    // The old loop let go where the new one takes over: a ringing piano
    // dies away as under a pianist's hands rather than being cut.
    _Tail? tail;
    if (oldThen != null && !carryOn && tailFor != null) {
      try {
        tail = await _Tail.load(
          tailFor,
          oldThen + (wait ?? Duration.zero),
          _length,
          since,
        );
      } catch (_) {
        // Without its tail the old loop is simply cut, as it used to be.
      }
    }
    final fade = carryOn && crossfade > Duration.zero;
    if (wait == null) {
      handle = _soloud.play(
        source,
        paused: true,
        looping: true,
        volume: fade ? 0 : _volume,
      );
      if (seekTo > Duration.zero) _soloud.seek(handle, seekTo);
      _soloud.setPause(handle, false);
      if (fade) _soloud.fadeVolume(handle, _volume, crossfade);
      tail?.playNow(_volume);
    } else {
      // The other loop is playing: come in on its next "one", on the
      // engine's own clock, read once for the start and the stop below.
      delay = wait;
      position = Duration.zero;
      startsAt = waitedFrom + wait;
      handle = _soloud.playScheduled(
        source,
        startsAt,
        looping: true,
        volume: _volume,
      );
      tail?.playAt(startsAt, _volume);
    }
    _handle = handle;
    _source = source;
    _length = length;
    _bar = bar;
    LoopTransport.instance.unregister(name, old);
    LoopTransport.instance.register(name, handle, bar, startsAt: startsAt);
    if (old != null && startsAt != null) {
      // The old loop plays on until the new one comes in, and stops at that
      // very sample, so that the two "ones" do not both sound.
      _soloud.stopScheduled(old, startsAt);
      Future<void>.delayed(delay + const Duration(milliseconds: 100), () {
        if (oldSource != null) _soloud.disposeSource(oldSource);
      });
    } else if (old != null && fade) {
      // Carrying on at a new tempo: the two cross over.
      _soloud.fadeVolume(old, 0, crossfade);
      _soloud.scheduleStop(old, crossfade);
      Future<void>.delayed(crossfade + const Duration(milliseconds: 100), () {
        if (oldSource != null) _soloud.disposeSource(oldSource);
      });
    } else {
      if (old != null) await _soloud.stop(old);
      if (oldSource != null) await _soloud.disposeSource(oldSource);
    }
    return (position: position, delay: delay);
  }

  /// Stops the loop. With [tailFor], what the loop sounds like let go
  /// where it is (see PianoSound.tailWav) plays on from that very sample.
  Future<void> stop({Uint8List Function(Duration position)? tailFor}) async {
    final handle = _handle, source = _source;
    _handle = null;
    _source = null;
    LoopTransport.instance.unregister(name, handle);
    if (handle != null &&
        tailFor != null &&
        _soloud.getIsValidVoiceHandle(handle)) {
      try {
        final since = Stopwatch()..start();
        final tail = await _Tail.load(
          tailFor,
          _soloud.getPosition(handle),
          _length,
          since,
        );
        tail.playNow(_volume);
      } catch (_) {
        // Without its tail the loop is simply cut, as it used to be.
      }
    }
    if (handle != null) await _soloud.stop(handle);
    if (source != null) await _soloud.disposeSource(source);
  }

  void setVolume(double volume) {
    _volume = volume;
    final handle = _handle;
    if (handle != null) _soloud.setVolume(handle, volume);
  }
}

/// What a loop sounds like let go at a place in it, ready to play from
/// that place on.
class _Tail {
  _Tail._(this._source, this._clock, this._length);

  /// Makes the tail of a loop of [length] let go at [position] (taken
  /// round the loop) and loads it. [clock] runs from when [position] was
  /// read, so that a tail played at once starts where the loop is by then.
  static Future<_Tail> load(
    Uint8List Function(Duration position) tailFor,
    Duration position,
    Duration length,
    Stopwatch clock,
  ) async {
    final at = length > Duration.zero
        ? Duration(
            microseconds: position.inMicroseconds % length.inMicroseconds,
          )
        : position;
    final wav = tailFor(at);
    final source = await SoLoud.instance.loadMem('tail.wav', wav);
    return _Tail._(source, clock, SoLoud.instance.getLength(source));
  }

  final AudioSource _source;
  final Stopwatch _clock;
  final Duration _length;

  SoLoud get _soloud => SoLoud.instance;

  /// From where the loop is now, which went on while the tail was made.
  void playNow(double volume) {
    final handle = _soloud.play(_source, paused: true, volume: volume);
    final skip = _clock.elapsed;
    if (skip < _length) _soloud.seek(handle, skip);
    _soloud.setPause(handle, false);
    _disposeAfter(_length);
  }

  /// From its start, at [time] on the engine's clock.
  void playAt(Duration time, double volume) {
    _soloud.playScheduled(_source, time, volume: volume);
    _disposeAfter(time - _soloud.getEngineTime() + _length);
  }

  void _disposeAfter(Duration wait) => Future<void>.delayed(
    wait + const Duration(milliseconds: 200),
    () => _soloud.disposeSource(_source),
  );
}
