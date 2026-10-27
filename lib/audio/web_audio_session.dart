/// Tells Safari on the iPhone what the web app's sound is for (its
/// navigator.audioSession, Safari 16.4 and later): music, so that the
/// silent switch does not mute the clicks and the piano, or music while the
/// microphone listens. Does nothing in the Android app and in the tests.
library;

export 'web_audio_session_stub.dart'
    if (dart.library.js_interop) 'web_audio_session_web.dart';
