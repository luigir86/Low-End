import 'package:flutter_soloud/flutter_soloud.dart';

Future<void>? _ready;

/// Starts the SoLoud audio engine once for the whole app, so the drone and
/// the metronome never start it twice at the same time. Tried again on the
/// next call if it failed.
Future<void> ensureSoLoud() => _ready ??=
    () async {
      if (!SoLoud.instance.isInitialized) await SoLoud.instance.init();
    }().catchError((Object error) {
      _ready = null;
      throw error;
    });
