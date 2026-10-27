import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while something plays or the tuner listens: with the
/// phone on the music stand, the ring of beats and the strobe must not go
/// dark after the phone's timeout, with both hands on the bass.
///
/// Kept behind an interface so the rest of the app can be tested without a
/// phone.
abstract class ScreenAwake {
  /// Keeps the screen on, or lets it turn off by itself again.
  Future<void> keepOn(bool on);
}

/// [ScreenAwake] backed by the wakelock_plus package.
class WakelockScreenAwake implements ScreenAwake {
  // On the web, the page's wake lock (Safari 16.4 and later).
  static bool get _supported => kIsWeb || Platform.isAndroid;

  bool? _on;

  @override
  Future<void> keepOn(bool on) async {
    if (!_supported || on == _on) return;
    _on = on;
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (error) {
      debugPrint('Screen could not be kept on: $error');
    }
  }
}

/// [ScreenAwake] that remembers what it was asked; used in tests.
@visibleForTesting
class FakeScreenAwake implements ScreenAwake {
  var on = false;

  @override
  Future<void> keepOn(bool on) async => this.on = on;
}
