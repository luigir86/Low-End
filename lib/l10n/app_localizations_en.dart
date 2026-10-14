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
  String get comingSoon => 'Coming soon';

  @override
  String get metronomeDescription =>
      'Precise metronome with accents and subdivisions.';

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
      'Tap Start listening, then play one note at a time.';

  @override
  String get playAString => 'Play a note';

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
  String playSound(String name) {
    return 'Play $name';
  }

  @override
  String get octaveDown => 'Octave down';

  @override
  String get octaveUp => 'Octave up';

  @override
  String get aboutTooltip => 'About Low End';

  @override
  String get aboutLegalese =>
      'Free and open-source software, released under the MIT License.';

  @override
  String get aboutDescription =>
      'Tuner, drone and metronome for double bass and electric bass. Low End works offline: the microphone is used only while the tuner is listening, and no sound or data leaves your phone.';

  @override
  String aboutSource(String url) {
    return 'Source code: $url';
  }
}
