import 'dart:js_interop';

@JS('lowEndAudioEngine')
external JSPromise<JSAny?>? get _loaded;

@JS('lowEndLoadAudioEngine')
external JSFunction? get _load;

@JS('lowEndAudioInUse')
external set _inUse(bool value);

/// Waits until the page has loaded the audio engine, starting it now if
/// the page has not yet (a sound asked for right after the first frame).
/// Pages without the loader (none today) are not waited for.
Future<void> webAudioEngineLoaded() async {
  markWebAudioInUse();
  final loaded = _loaded;
  if (loaded == null) return;
  _load?.callAsFunction();
  await loaded.toDart;
}

/// Tells the page that a sound or the microphone has started, so that it is
/// not reloaded under the player's hands (see web/flutter_bootstrap.js).
void markWebAudioInUse() => _inUse = true;
