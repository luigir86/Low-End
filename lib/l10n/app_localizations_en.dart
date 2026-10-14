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

  @override
  String get startListening => 'Start listening';

  @override
  String get stopListening => 'Stop listening';

  @override
  String get tunerIdleHint =>
      'Tap Start listening, then play one string at a time.';

  @override
  String get playAString => 'Play a string';

  @override
  String get micPermissionDenied =>
      'Low End needs the microphone to hear your bass. If you said no, allow it in the phone settings under Apps › Low End › Permissions.';

  @override
  String get micUnavailable => 'The microphone could not start on this device.';

  @override
  String get inTune => 'In tune';

  @override
  String get flat => 'Flat';

  @override
  String get sharp => 'Sharp';

  @override
  String centsValue(String cents) {
    return '$cents cents';
  }

  @override
  String playingNote(String note) {
    return 'You are playing $note';
  }

  @override
  String get tuningLabel => 'Tuning';

  @override
  String get chromatic => 'Chromatic (any note)';

  @override
  String get doubleBass => 'Double bass';

  @override
  String get electricBass => 'Electric bass';

  @override
  String tuningName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'orchestral': 'Orchestral',
      'solo': 'Solo',
      'cExtension': 'C extension',
      'fiveLowB': '5 strings, low B',
      'fiveHighC': '5 strings, high C',
      'fourStrings': '4 strings',
      'fiveStrings': '5 strings',
      'sixStrings': '6 strings',
      'dropD': 'Drop D',
      'other': '$id',
    });
    return '$_temp0';
  }
}
