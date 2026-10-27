import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'app/licenses.dart';
import 'app/low_end_app.dart';
import 'app/settings.dart';
import 'audio/web_audio_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // In a web page Flutter shows the screen to VoiceOver and TalkBack only
    // when asked; the app must be usable with them from the start.
    SemanticsBinding.instance.ensureSemantics();
    // Music: the iPhone's silent switch must not mute the clicks.
    setWebAudioSession(listening: false);
  }
  // A quick read of a small file, so the app opens in the chosen language.
  AppSettings settings;
  try {
    settings = await AppSettings.load();
  } catch (error) {
    // Unreadable settings must never keep the app from opening: it then
    // starts with the defaults, which are not saved.
    debugPrint('Settings could not be read: $error');
    settings = AppSettings();
  }
  registerAssetLicenses();
  runApp(LowEndApp(settings: settings));
}
