// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Low End';

  @override
  String get tunerTab => 'Accordatore';

  @override
  String get metronomeTab => 'Metronomo';

  @override
  String get libraryTab => 'Libreria';

  @override
  String get comingSoon => 'In arrivo';

  @override
  String get tunerDescription =>
      'Accordatore per contrabbasso e basso elettrico, fino al Si grave.';

  @override
  String get metronomeDescription =>
      'Metronomo preciso con accenti e suddivisioni.';

  @override
  String get libraryDescription =>
      'Le tue partiture PDF, scalette e annotazioni.';
}
