import 'package:flutter/material.dart';

import 'app/licenses.dart';
import 'app/low_end_app.dart';
import 'app/settings.dart';
import 'audio/click_sound.dart';
import 'audio/drum_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  // The metronome's recorded strokes: six small files. Without them (they
  // cannot fail to be there, but nothing must stop the app) the ride made in
  // code plays instead.
  try {
    ClickSound.kit = await DrumKit.load();
  } catch (error) {
    debugPrint('Drum sounds could not be read: $error');
  }
  registerAssetLicenses();
  runApp(LowEndApp(settings: settings));
}
