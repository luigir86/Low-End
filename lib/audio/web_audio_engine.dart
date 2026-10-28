/// The web app's audio engine, which the page loads after the first frame
/// (web/flutter_bootstrap.js). Does nothing in the Android app and in the
/// tests.
library;

export 'web_audio_engine_stub.dart'
    if (dart.library.js_interop) 'web_audio_engine_web.dart';
