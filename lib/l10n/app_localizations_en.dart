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
  String get droneMode => 'Drone';

  @override
  String get metronomeStart => 'Start the metronome';

  @override
  String get metronomeStop => 'Stop the metronome';

  @override
  String get metronomeHint => 'Tap to start';

  @override
  String bpmValue(String bpm) {
    return '$bpm BPM';
  }

  @override
  String get timeSignature => 'Time signature';

  @override
  String get backgroundPlaying => 'Playing in the background';

  @override
  String get holdToToggle => 'Hold to start or stop';

  @override
  String get slower => 'Slower';

  @override
  String get faster => 'Faster';

  @override
  String get tapTempo => 'Tap the tempo';

  @override
  String get droneStop => 'Stop the drone';

  @override
  String get progressionLabel => 'Progression';

  @override
  String get progressionMinorTwoFiveOne => 'II–V–I minor';

  @override
  String get progressionBlues => '12-bar blues';

  @override
  String get addSevenths => 'Add the seventh to the chords';

  @override
  String degreeOf(String degree, String key) {
    return '$degree of $key';
  }

  @override
  String droneChordDiminished(String note) {
    return '$note diminished';
  }

  @override
  String get balanceLabel => 'Metronome and drone balance';

  @override
  String balanceValue(String metronome, String drone) {
    return 'Metronome $metronome%, drone $drone%';
  }

  @override
  String get referencePitch => 'Reference A';

  @override
  String referencePitchHint(String note) {
    return 'The frequency of $note, for the tuner and the drone.';
  }

  @override
  String frequencyHz(String frequency) {
    return '$frequency Hz';
  }

  @override
  String stopSound(String name) {
    return 'Stop $name';
  }

  @override
  String playSound(String name) {
    return 'Play $name';
  }

  @override
  String get droneHint => 'Touch a note to play it. Touch it again to stop.';

  @override
  String get rootOnly => 'Root';

  @override
  String get chordLabel => 'Chord';

  @override
  String get chordMajor => 'Major';

  @override
  String get chordMinor => 'Minor';

  @override
  String get chordSeventh => '7';

  @override
  String droneChordMajor(String note) {
    return '$note major';
  }

  @override
  String droneChordMinor(String note) {
    return '$note minor';
  }

  @override
  String droneChordSeventh(String note) {
    return '${note}7';
  }

  @override
  String get audioUnavailable => 'Sound could not start on this device.';

  @override
  String get startListening => 'Listen';

  @override
  String get stopListening => 'Pause';

  @override
  String get tunerIdleHint => 'Paused';

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
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'Same as the phone';

  @override
  String get noteNamesLabel => 'Note names';

  @override
  String get noteNamesAuto => 'Follow the language';

  @override
  String get noteNamesSolfege => 'Do Re Mi (La3 = 440 Hz)';

  @override
  String get noteNamesLetters => 'C D E (A4 = 440 Hz)';

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
