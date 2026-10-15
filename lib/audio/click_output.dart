import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'soloud_engine.dart';

/// Loops one bar of metronome clicks.
///
/// Kept behind an interface so the rest of the app can be tested without a
/// real audio device.
abstract class ClickOutput {
  /// Starts looping [barWav] (see ClickSound.bar), [startAt] into the bar,
  /// replacing the bar already playing, if any.
  Future<void> play(Uint8List barWav, Duration startAt);

  Future<void> stop();
}

/// [ClickOutput] backed by the SoLoud audio engine.
///
/// Calls are expected one at a time (MetronomeController waits for each
/// one to finish before the next).
class SoLoudClickOutput implements ClickOutput {
  AudioSource? _source;
  SoundHandle? _handle;

  SoLoud get _soloud => SoLoud.instance;

  @override
  Future<void> play(Uint8List barWav, Duration startAt) async {
    await ensureSoLoud();
    final source = await _soloud.loadMem('metronome-bar.wav', barWav);
    // Start the new bar where the old one was, then drop the old one: a
    // tempo change keeps the beat going instead of restarting the bar.
    final handle = _soloud.play(source, paused: true, looping: true);
    if (startAt > Duration.zero) _soloud.seek(handle, startAt);
    _soloud.setPause(handle, false);
    await _release();
    _source = source;
    _handle = handle;
  }

  @override
  Future<void> stop() => _release();

  Future<void> _release() async {
    final handle = _handle, source = _source;
    _handle = null;
    _source = null;
    if (handle != null) await _soloud.stop(handle);
    if (source != null) await _soloud.disposeSource(source);
  }
}

/// [ClickOutput] that makes no sound; used where audio is unavailable.
@visibleForTesting
class SilentClickOutput implements ClickOutput {
  /// The bar playing now, or null when stopped.
  Uint8List? bar;
  Duration startAt = Duration.zero;
  var plays = 0;

  @override
  Future<void> play(Uint8List barWav, Duration startAt) async {
    bar = barWav;
    this.startAt = startAt;
    plays++;
  }

  @override
  Future<void> stop() async => bar = null;
}
