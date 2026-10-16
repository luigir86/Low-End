import 'package:flutter/foundation.dart';

import 'bar_loop_player.dart';
import 'click_sound.dart';
import 'loop_transport.dart';

/// Loops one bar of metronome clicks.
///
/// Kept behind an interface so the rest of the app can be tested without a
/// real audio device.
abstract class ClickOutput {
  /// Starts looping [barWav] (see ClickSound.bar), replacing the bar
  /// already playing, if any.
  ///
  /// With no [startAt], a bar replacing another carries on from where the
  /// old one was (scaled to its own length), as a tempo change should, and
  /// the piano does the same. With one, it starts that far into the bar; if
  /// the piano is playing it then waits for the piano's next bar line, so
  /// the two stay together. Says where and when it began.
  Future<LoopStart> play(Uint8List barWav, {Duration? startAt});

  Future<void> stop();

  /// Sets the level, 0 to 1, of the clicks now and of later bars.
  void setVolume(double volume);
}

/// [ClickOutput] backed by the SoLoud audio engine.
class SoLoudClickOutput implements ClickOutput {
  final _player = BarLoopPlayer('click');

  @override
  Future<LoopStart> play(Uint8List barWav, {Duration? startAt}) {
    // The loop is one bar long.
    final bar = Duration(
      microseconds:
          (barWav.length - 44) ~/ 2 * 1000000 ~/ ClickSound.sampleRate,
    );
    return _player.play(barWav, bar, startAt: startAt);
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  void setVolume(double volume) => _player.setVolume(volume);
}

/// [ClickOutput] that makes no sound; used where audio is unavailable.
@visibleForTesting
class SilentClickOutput implements ClickOutput {
  /// The bar playing now, or null when stopped.
  Uint8List? bar;
  Duration? startAt;
  var plays = 0;

  /// How long the next start waits, as if the piano were playing.
  Duration delay = Duration.zero;

  @override
  Future<LoopStart> play(Uint8List barWav, {Duration? startAt}) async {
    bar = barWav;
    this.startAt = startAt;
    plays++;
    return (position: startAt ?? Duration.zero, delay: delay);
  }

  @override
  Future<void> stop() async => bar = null;

  double volume = 1;

  @override
  void setVolume(double volume) => this.volume = volume;
}
