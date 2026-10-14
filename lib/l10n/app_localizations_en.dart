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

  @override
  String get tuneMode => 'Tune';

  @override
  String get droneMode => 'Drone';

  @override
  String get noteLabel => 'Note';

  @override
  String get octaveLabel => 'Octave';

  @override
  String get addFifth => 'Add the fifth';

  @override
  String get addOctave => 'Add the octave above';

  @override
  String get referencePitch => 'Reference A';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get play => 'Play';

  @override
  String get stop => 'Stop';

  @override
  String frequencyHz(String frequency) {
    return '$frequency Hz';
  }

  @override
  String get lowNoteWarning =>
      'Phone speakers can barely play notes this low. Use headphones or an external speaker.';

  @override
  String droneNowPlaying(String note) {
    return 'Drone · $note';
  }

  @override
  String stopSound(String name) {
    return 'Stop $name';
  }

  @override
  String get droneShortcutHint =>
      'Practise with the drone and the click together.';

  @override
  String get audioUnavailable => 'Sound could not start on this device.';
}
