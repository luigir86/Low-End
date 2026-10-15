import 'package:flutter/material.dart';

import 'app/low_end_app.dart';
import 'app/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // A quick read of a small file, so the app opens in the chosen language.
  final settings = await AppSettings.load();
  runApp(LowEndApp(settings: settings));
}
