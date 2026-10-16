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
  BarLoopPlayer(this.name);

  /// 'click' or 'piano': how the other loop knows this one.
  final String name;

  AudioSource? _source;
  SoundHandle? _handle;
  Duration _length = Duration.zero;
  double _volume = 1;

  SoLoud get _soloud => SoLoud.instance;

  bool get isPlaying => _handle != null;

  /// Loops [wav], whose bars last [bar] (the loop is a whole number of
  /// them), replacing the loop already playing, if any.
  ///
  /// With no [startAt], a loop replacing another carries on from where the
  /// old one is, scaled to its own length, as a tempo change should. With
  /// one (or when nothing was playing), it starts that far in; if the other
  /// loop is playing it then waits for that loop's next bar line, so that
  /// the two stay together. Says where and when it began.
  Future<LoopStart> play(
    Uint8List wav,
    Duration bar, {
    Duration? startAt,
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
    var position = startAt ?? Duration.zero;
    var delay = Duration.zero;
    if (carryOn) {
      // The old loop's place, as a fraction of its length.
      final was =
          _soloud.getPosition(old).inMicroseconds % _length.inMicroseconds;
      position = Duration(
        microseconds: (was * length.inMicroseconds / _length.inMicroseconds)
            .round(),
      );
    }
    final SoundHandle handle;
    if (wait == null) {
      handle = _soloud.play(
        source,
        paused: true,
        looping: true,
        volume: _volume,
      );
      if (position > Duration.zero) _soloud.seek(handle, position);
      _soloud.setPause(handle, false);
    } else {
      // The other loop is playing: come in on its next "one".
      delay = wait;
      position = Duration.zero;
      handle = _soloud.playScheduled(
        source,
        _soloud.getEngineTime() + wait,
        looping: true,
        volume: _volume,
      );
    }
    _handle = handle;
    _source = source;
    _length = length;
    LoopTransport.instance.unregister(name, old);
    LoopTransport.instance.register(name, handle, bar);
    if (old != null && delay > Duration.zero) {
      // The old loop plays on until the new one comes in.
      _soloud.scheduleStop(old, delay);
      Future<void>.delayed(delay + const Duration(milliseconds: 100), () {
        if (oldSource != null) _soloud.disposeSource(oldSource);
      });
    } else {
      if (old != null) await _soloud.stop(old);
      if (oldSource != null) await _soloud.disposeSource(oldSource);
    }
    return (position: position, delay: delay);
  }

  Future<void> stop() async {
    final handle = _handle, source = _source;
    _handle = null;
    _source = null;
    LoopTransport.instance.unregister(name, handle);
    if (handle != null) await _soloud.stop(handle);
    if (source != null) await _soloud.disposeSource(source);
  }

  void setVolume(double volume) {
    _volume = volume;
    final handle = _handle;
    if (handle != null) _soloud.setVolume(handle, volume);
  }
}
