import 'package:flutter_soloud/flutter_soloud.dart';

/// Which looping bar is playing, so that a second one starting while the
/// first plays comes in on its "one" instead of at a random point: the
/// metronome's clicks and the piano's chords are two loops of the same
/// length (or of a whole number of bars), and must stay together.
class LoopTransport {
  LoopTransport._();

  static final instance = LoopTransport._();

  final _loops = <String, _Loop>{};

  SoLoud get _soloud => SoLoud.instance;

  /// Notes that the loop [name], playing as [handle], has bars of [bar].
  void register(String name, SoundHandle handle, Duration bar) =>
      _loops[name] = _Loop(handle, bar);

  void unregister(String name, SoundHandle? handle) {
    if (handle != null && _loops[name]?.handle == handle) _loops.remove(name);
  }

  /// Time until the next bar line of a loop other than [name], or null if
  /// no other loop is playing. Never less than [minimum], so that there is
  /// time to schedule a start: a bar line too close is skipped.
  Duration? untilBarLine(
    String name, {
    Duration minimum = const Duration(milliseconds: 60),
  }) {
    for (final e in _loops.entries) {
      if (e.key == name) continue;
      final loop = e.value;
      try {
        if (!_soloud.getIsValidVoiceHandle(loop.handle)) continue;
        final bar = loop.bar.inMicroseconds;
        final at = _soloud.getPosition(loop.handle).inMicroseconds % bar;
        var wait = Duration(microseconds: bar - at);
        while (wait < minimum) {
          wait += loop.bar;
        }
        return wait;
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}

class _Loop {
  const _Loop(this.handle, this.bar);

  final SoundHandle handle;
  final Duration bar;
}

/// Where a loop actually began: [position] into the loop at the moment it
/// started to sound, and [delay], how long from the call that was, when it
/// had to wait for the other loop's next bar line.
typedef LoopStart = ({Duration position, Duration delay});
