import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// How long the engine plays silence after it starts, before the first
/// sound: the phone's audio output is still ramping up (routing to the
/// speaker, fading in), and a click that begins at that moment comes out as
/// a double "tra-ta" instead of one tick.
const engineWarmUp = Duration(milliseconds: 300);

/// Starts an audio engine once, and lets the first sound wait until it has
/// warmed up. Tried again on the next call if it failed.
@visibleForTesting
class EngineStarter {
  EngineStarter(this._start, {this.warmUp = engineWarmUp});

  final Future<void> Function() _start;
  final Duration warmUp;
  Future<void>? _ready;

  Future<void> ensure() => _ready ??=
      (() async {
        await _start();
        await Future<void>.delayed(warmUp);
      })().catchError((Object error) {
        _ready = null;
        throw error;
      });
}

final _engine = EngineStarter(() async {
  if (!SoLoud.instance.isInitialized) await SoLoud.instance.init();
});

/// Starts the SoLoud audio engine once for the whole app, so the drone and
/// the metronome never start it twice at the same time. Tried again on the
/// next call if it failed. The first call comes back once the engine has
/// warmed up (see [engineWarmUp]); later ones at once.
Future<void> ensureSoLoud() => _engine.ensure();
