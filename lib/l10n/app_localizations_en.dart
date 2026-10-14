// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Low End';

  @override
  String get tunerTab => 'Tuner';

  @override
  String get metronomeTab => 'Metronome';

  @override
  String get libraryTab => 'Library';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get tunerDescription =>
      'Tuner for double bass and electric bass, down to low B.';

  @override
  String get metronomeDescription =>
      'Precise metronome with accents and subdivisions.';

  @override
  String get libraryDescription =>
      'Your PDF scores, set lists and annotations.';
}
