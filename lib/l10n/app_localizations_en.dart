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
  String get harmonyTab => 'Harmony';

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
  String get droneStop => 'Stop the harmony';

  @override
  String get feelLabel => 'Feel';

  @override
  String get feelStraight => 'Straight';

  @override
  String get feelSwing => 'Swing';

  @override
  String get feelShuffle => 'Shuffle';

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
  String get balanceLabel => 'Balance between the metronome and the harmony';

  @override
  String balanceValue(String metronome, String drone) {
    return 'Metronome $metronome%, harmony $drone%';
  }

  @override
  String get referencePitch => 'Reference A';

  @override
  String referencePitchHint(String note) {
    return 'The frequency of $note, for the tuner and the harmony.';
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
  String get tunerIdleHint => 'Tuner paused: tap Listen';

  @override
  String get playAString => 'Play a note';

  @override
  String get micPermissionDenied =>
      'Low End needs the microphone to hear your instrument. If you said no, allow it in the phone settings under Apps › Low End › Permissions.';

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
  String get circleLayoutLabel => 'Harmony circle';

  @override
  String get circleLayoutFifths => 'Circle of fifths';

  @override
  String get circleLayoutChromatic => 'In semitones (C, C♯, D…)';

  @override
  String get aboutTooltip => 'About Low End';

  @override
  String get aboutLegalese =>
      'Free and open-source software, released under the MIT License.';

  @override
  String get aboutDescription =>
      'Metronome, harmony and tuner for musicians. Made by an amateur double bass player with the friends from the orchestra in mind, and useful to everyone. Low End works offline: the microphone is used only while the tuner is listening, and no sound or data leaves your phone.';

  @override
  String get aboutPiano =>
      'Piano sounds: Salamander Grand Piano by Alexander Holm (public domain).';

  @override
  String get styleLabel => 'Style';

  @override
  String get styleHeld => 'Chord every bar';

  @override
  String get styleBeat => 'Chord on every beat';

  @override
  String get styleArpeggio => 'Arpeggio';

  @override
  String styleTempo(String tempo, String signature) {
    return 'Follows the metronome: $tempo, $signature';
  }

  @override
  String get beatUnitQuarter => 'quarter note';

  @override
  String get beatUnitDottedQuarter => 'dotted quarter note';

  @override
  String get beatUnitEighth => 'eighth note';

  @override
  String get pausedForTuner => 'Paused while you tune';

  @override
  String get resume => 'Resume';

  @override
  String get playing => 'Playing';

  @override
  String get openSettings => 'Open settings';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'Follow the phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get keepScreenOnTitle => 'Keep the screen on';

  @override
  String get keepScreenOnSubtitle => 'While it plays or the tuner listens';

  @override
  String get setTempo => 'Type the tempo';

  @override
  String get optionsLabel => 'Sound options';

  @override
  String get octaveLabel => 'Octave of the root';

  @override
  String get shapeLabel => 'Chord position';

  @override
  String get shapeStacked => 'Stacked';

  @override
  String get shapeClose => 'Close';

  @override
  String get shapeRootless => 'No root';

  @override
  String get guideTitle => 'Gestures and shortcuts';

  @override
  String get guideRing => 'Tap the metronome\'s ring to start and stop it.';

  @override
  String get guideTempo =>
      'Tap the number to type the tempo. Hold − or + to move in steps of 5 and 10.';

  @override
  String get guideSwipe => 'Swipe left and right to change section.';

  @override
  String get guideHold =>
      'Hold a tab to start or stop its sound from any section.';

  @override
  String get guideDrone =>
      'In Harmony, tap a note to play it. Hold C♯ or F♯ to write them D♭ or G♭.';

  @override
  String get guideTuner =>
      'The tuner listens by itself. Going there pauses the metronome and the harmony.';

  @override
  String get guideVolume =>
      'The volume is the phone\'s: use its volume keys. The slider at the bottom only balances the metronome and the harmony.';

  @override
  String get guideDone => 'Got it';

  @override
  String writeAs(String note) {
    return 'Write as $note';
  }

  @override
  String aboutSource(String url) {
    return 'Source code: $url';
  }
}
