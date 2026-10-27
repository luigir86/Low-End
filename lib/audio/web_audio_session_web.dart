import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

@JS('navigator')
external JSObject get _navigator;

/// See web_audio_session.dart. Browsers without an audio session (all but
/// Safari) are left alone.
void setWebAudioSession({required bool listening}) {
  try {
    final session = _navigator['audioSession'];
    if (session == null) return;
    (session as JSObject)['type'] =
        (listening ? 'play-and-record' : 'playback').toJS;
  } catch (error) {
    debugPrint('Audio session could not be set: $error');
  }
}
