import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Low End'**
  String get appTitle;

  /// No description provided for @tunerTab.
  ///
  /// In en, this message translates to:
  /// **'Tuner'**
  String get tunerTab;

  /// No description provided for @metronomeTab.
  ///
  /// In en, this message translates to:
  /// **'Metronome'**
  String get metronomeTab;

  /// No description provided for @harmonyTab.
  ///
  /// In en, this message translates to:
  /// **'Harmony'**
  String get harmonyTab;

  /// No description provided for @metronomeStart.
  ///
  /// In en, this message translates to:
  /// **'Start the metronome'**
  String get metronomeStart;

  /// No description provided for @metronomeStop.
  ///
  /// In en, this message translates to:
  /// **'Stop the metronome'**
  String get metronomeStop;

  /// No description provided for @metronomeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to start'**
  String get metronomeHint;

  /// No description provided for @bpmValue.
  ///
  /// In en, this message translates to:
  /// **'{bpm} BPM'**
  String bpmValue(String bpm);

  /// No description provided for @timeSignature.
  ///
  /// In en, this message translates to:
  /// **'Time signature'**
  String get timeSignature;

  /// No description provided for @backgroundPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing in the background'**
  String get backgroundPlaying;

  /// No description provided for @holdToToggle.
  ///
  /// In en, this message translates to:
  /// **'Hold to start or stop'**
  String get holdToToggle;

  /// No description provided for @slower.
  ///
  /// In en, this message translates to:
  /// **'Slower'**
  String get slower;

  /// No description provided for @faster.
  ///
  /// In en, this message translates to:
  /// **'Faster'**
  String get faster;

  /// No description provided for @tapTempo.
  ///
  /// In en, this message translates to:
  /// **'Tap the tempo'**
  String get tapTempo;

  /// No description provided for @droneStop.
  ///
  /// In en, this message translates to:
  /// **'Stop the harmony'**
  String get droneStop;

  /// No description provided for @feelLabel.
  ///
  /// In en, this message translates to:
  /// **'Feel'**
  String get feelLabel;

  /// No description provided for @feelStraight.
  ///
  /// In en, this message translates to:
  /// **'Straight'**
  String get feelStraight;

  /// No description provided for @feelSwing.
  ///
  /// In en, this message translates to:
  /// **'Swing'**
  String get feelSwing;

  /// No description provided for @progressionLabel.
  ///
  /// In en, this message translates to:
  /// **'Progression'**
  String get progressionLabel;

  /// No description provided for @progressionMinorTwoFiveOne.
  ///
  /// In en, this message translates to:
  /// **'II–V–I minor'**
  String get progressionMinorTwoFiveOne;

  /// No description provided for @progressionBlues.
  ///
  /// In en, this message translates to:
  /// **'12-bar blues'**
  String get progressionBlues;

  /// No description provided for @progressionGenreJazz.
  ///
  /// In en, this message translates to:
  /// **'Jazz standard'**
  String get progressionGenreJazz;

  /// No description provided for @progressionGenreMinorJazz.
  ///
  /// In en, this message translates to:
  /// **'Jazz in a minor key'**
  String get progressionGenreMinorJazz;

  /// No description provided for @progressionGenreRock.
  ///
  /// In en, this message translates to:
  /// **'Rock ’n’ roll'**
  String get progressionGenreRock;

  /// No description provided for @progressionGenrePop.
  ///
  /// In en, this message translates to:
  /// **'’50s–’60s pop'**
  String get progressionGenrePop;

  /// No description provided for @progressionGenreBlues.
  ///
  /// In en, this message translates to:
  /// **'Blues'**
  String get progressionGenreBlues;

  /// A progression described by its genre and a well-known song that uses it, in the progression menu.
  ///
  /// In en, this message translates to:
  /// **'{genre}, like {song}'**
  String progressionLike(String genre, String song);

  /// No description provided for @thanksTitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks'**
  String get thanksTitle;

  /// No description provided for @thanksText.
  ///
  /// In en, this message translates to:
  /// **'Thanks to the Power Flower Orchestra of Fossano, who inspired this app and put it to the test.'**
  String get thanksText;

  /// No description provided for @addSevenths.
  ///
  /// In en, this message translates to:
  /// **'Add the seventh to the chords'**
  String get addSevenths;

  /// No description provided for @droneChordDiminished.
  ///
  /// In en, this message translates to:
  /// **'{note} diminished'**
  String droneChordDiminished(String note);

  /// No description provided for @balanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance between the metronome and the harmony'**
  String get balanceLabel;

  /// No description provided for @balanceValue.
  ///
  /// In en, this message translates to:
  /// **'Metronome {metronome}%, harmony {drone}%'**
  String balanceValue(String metronome, String drone);

  /// No description provided for @referencePitch.
  ///
  /// In en, this message translates to:
  /// **'Reference A'**
  String get referencePitch;

  /// No description provided for @lowerPitch.
  ///
  /// In en, this message translates to:
  /// **'Lower the reference A'**
  String get lowerPitch;

  /// No description provided for @higherPitch.
  ///
  /// In en, this message translates to:
  /// **'Raise the reference A'**
  String get higherPitch;

  /// No description provided for @choosePitch.
  ///
  /// In en, this message translates to:
  /// **'Choose a standard reference A'**
  String get choosePitch;

  /// No description provided for @pitchBaroque.
  ///
  /// In en, this message translates to:
  /// **'Baroque'**
  String get pitchBaroque;

  /// No description provided for @pitchVerdi.
  ///
  /// In en, this message translates to:
  /// **'Verdi'**
  String get pitchVerdi;

  /// No description provided for @pitchConcert.
  ///
  /// In en, this message translates to:
  /// **'Concert pitch'**
  String get pitchConcert;

  /// No description provided for @pitchOrchestras.
  ///
  /// In en, this message translates to:
  /// **'Orchestras'**
  String get pitchOrchestras;

  /// No description provided for @referencePitchHint.
  ///
  /// In en, this message translates to:
  /// **'The frequency of {note}, for the tuner and the harmony.'**
  String referencePitchHint(String note);

  /// No description provided for @frequencyHz.
  ///
  /// In en, this message translates to:
  /// **'{frequency} Hz'**
  String frequencyHz(String frequency);

  /// No description provided for @stopSound.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}'**
  String stopSound(String name);

  /// No description provided for @playSound.
  ///
  /// In en, this message translates to:
  /// **'Play {name}'**
  String playSound(String name);

  /// No description provided for @droneHint.
  ///
  /// In en, this message translates to:
  /// **'Touch a note to play it. Touch it again to stop.'**
  String get droneHint;

  /// No description provided for @rootOnly.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get rootOnly;

  /// No description provided for @chordLabel.
  ///
  /// In en, this message translates to:
  /// **'Chord'**
  String get chordLabel;

  /// No description provided for @chordMajor.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get chordMajor;

  /// No description provided for @chordMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get chordMinor;

  /// No description provided for @chordSeventh.
  ///
  /// In en, this message translates to:
  /// **'Dominant 7th'**
  String get chordSeventh;

  /// The half-diminished seventh chord (m7♭5) in the middle of the drone dial.
  ///
  /// In en, this message translates to:
  /// **'{note} half-diminished'**
  String droneChordHalfDiminished(String note);

  /// The chord in the middle of the drone dial, such as A major.
  ///
  /// In en, this message translates to:
  /// **'{note} major'**
  String droneChordMajor(String note);

  /// No description provided for @droneChordMinor.
  ///
  /// In en, this message translates to:
  /// **'{note} minor'**
  String droneChordMinor(String note);

  /// No description provided for @droneChordSeventh.
  ///
  /// In en, this message translates to:
  /// **'{note}7'**
  String droneChordSeventh(String note);

  /// No description provided for @audioUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sound could not start on this device.'**
  String get audioUnavailable;

  /// No description provided for @startListening.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get startListening;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get stopListening;

  /// No description provided for @tunerIdleHint.
  ///
  /// In en, this message translates to:
  /// **'Tuner paused: tap Listen'**
  String get tunerIdleHint;

  /// No description provided for @playAString.
  ///
  /// In en, this message translates to:
  /// **'Play a note'**
  String get playAString;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Low End needs the microphone to hear your instrument. If you said no, allow it in the phone settings under Apps › Low End › Permissions.'**
  String get micPermissionDenied;

  /// No description provided for @micUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The microphone could not start on this device.'**
  String get micUnavailable;

  /// No description provided for @inTune.
  ///
  /// In en, this message translates to:
  /// **'In tune'**
  String get inTune;

  /// No description provided for @flat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get flat;

  /// No description provided for @sharp.
  ///
  /// In en, this message translates to:
  /// **'Sharp'**
  String get sharp;

  /// No description provided for @centsValue.
  ///
  /// In en, this message translates to:
  /// **'{cents} cents'**
  String centsValue(String cents);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as the phone'**
  String get languageSystem;

  /// No description provided for @noteNamesLabel.
  ///
  /// In en, this message translates to:
  /// **'Note names'**
  String get noteNamesLabel;

  /// No description provided for @noteNamesAuto.
  ///
  /// In en, this message translates to:
  /// **'Follow the language'**
  String get noteNamesAuto;

  /// No description provided for @noteNamesSolfege.
  ///
  /// In en, this message translates to:
  /// **'Do Re Mi (La3 = 440 Hz)'**
  String get noteNamesSolfege;

  /// No description provided for @noteNamesLetters.
  ///
  /// In en, this message translates to:
  /// **'C D E (A4 = 440 Hz)'**
  String get noteNamesLetters;

  /// No description provided for @circleLayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Harmony circle'**
  String get circleLayoutLabel;

  /// No description provided for @circleLayoutFifths.
  ///
  /// In en, this message translates to:
  /// **'Circle of fifths'**
  String get circleLayoutFifths;

  /// No description provided for @circleLayoutChromatic.
  ///
  /// In en, this message translates to:
  /// **'In semitones (C, C♯, D…)'**
  String get circleLayoutChromatic;

  /// No description provided for @aboutTooltip.
  ///
  /// In en, this message translates to:
  /// **'About Low End'**
  String get aboutTooltip;

  /// No description provided for @aboutLegalese.
  ///
  /// In en, this message translates to:
  /// **'Free and open-source software, released under the MIT License.'**
  String get aboutLegalese;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Metronome, harmony and tuner for musicians. Made by an amateur double bass player with the friends from the orchestra in mind, and useful to everyone. Low End works offline: the microphone is used only while the tuner is listening, and no sound or data leaves your phone.'**
  String get aboutDescription;

  /// No description provided for @aboutPiano.
  ///
  /// In en, this message translates to:
  /// **'Piano sounds: Salamander Grand Piano by Alexander Holm (public domain).'**
  String get aboutPiano;

  /// No description provided for @styleLabel.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get styleLabel;

  /// No description provided for @styleHeld.
  ///
  /// In en, this message translates to:
  /// **'Chord every bar'**
  String get styleHeld;

  /// No description provided for @styleBeat.
  ///
  /// In en, this message translates to:
  /// **'Chord on every beat'**
  String get styleBeat;

  /// No description provided for @styleArpeggio.
  ///
  /// In en, this message translates to:
  /// **'Arpeggio'**
  String get styleArpeggio;

  /// The tempo is written like ♩ = 120.
  ///
  /// In en, this message translates to:
  /// **'Follows the metronome: {tempo}, {signature}'**
  String styleTempo(String tempo, String signature);

  /// No description provided for @beatUnitQuarter.
  ///
  /// In en, this message translates to:
  /// **'quarter note'**
  String get beatUnitQuarter;

  /// No description provided for @beatUnitDottedQuarter.
  ///
  /// In en, this message translates to:
  /// **'dotted quarter note'**
  String get beatUnitDottedQuarter;

  /// No description provided for @beatUnitEighth.
  ///
  /// In en, this message translates to:
  /// **'eighth note'**
  String get beatUnitEighth;

  /// No description provided for @pausedForTuner.
  ///
  /// In en, this message translates to:
  /// **'Paused while you tune'**
  String get pausedForTuner;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow the phone'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @keepScreenOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the screen on'**
  String get keepScreenOnTitle;

  /// No description provided for @keepScreenOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'While it plays or the tuner listens'**
  String get keepScreenOnSubtitle;

  /// No description provided for @setTempo.
  ///
  /// In en, this message translates to:
  /// **'Type the tempo'**
  String get setTempo;

  /// No description provided for @optionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound options'**
  String get optionsLabel;

  /// No description provided for @octaveLabel.
  ///
  /// In en, this message translates to:
  /// **'Octave of the root'**
  String get octaveLabel;

  /// No description provided for @octaveSpeakerNote.
  ///
  /// In en, this message translates to:
  /// **'Low notes are faint on the phone’s own speaker: use headphones or a speaker, or pick the highest octave.'**
  String get octaveSpeakerNote;

  /// No description provided for @swipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe up or down over the dial or the tabs to change section.'**
  String get swipeHint;

  /// No description provided for @gesturesLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock the gestures'**
  String get gesturesLockedTitle;

  /// No description provided for @gesturesLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For rehearsals: no swiping between sections and no holding a tab, only taps'**
  String get gesturesLockedSubtitle;

  /// No description provided for @inTuneZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Tuner: in tune within'**
  String get inTuneZoneTitle;

  /// No description provided for @inTuneZoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How far off a note can be and still show as in tune'**
  String get inTuneZoneSubtitle;

  /// No description provided for @shapeLabel.
  ///
  /// In en, this message translates to:
  /// **'Chord position'**
  String get shapeLabel;

  /// No description provided for @shapeStacked.
  ///
  /// In en, this message translates to:
  /// **'Stacked'**
  String get shapeStacked;

  /// No description provided for @shapeClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get shapeClose;

  /// No description provided for @shapeRootless.
  ///
  /// In en, this message translates to:
  /// **'No root'**
  String get shapeRootless;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'Gestures and shortcuts'**
  String get guideTitle;

  /// No description provided for @guideRing.
  ///
  /// In en, this message translates to:
  /// **'Tap the metronome\'s ring to start and stop it.'**
  String get guideRing;

  /// No description provided for @guideTempo.
  ///
  /// In en, this message translates to:
  /// **'Tap the number to type the tempo. Hold − or + to move in steps of 5 and 10.'**
  String get guideTempo;

  /// No description provided for @guideSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe left and right to change section.'**
  String get guideSwipe;

  /// No description provided for @guideSwipeVertical.
  ///
  /// In en, this message translates to:
  /// **'Turned sideways, swipe up and down over the dial or the tabs to change section.'**
  String get guideSwipeVertical;

  /// No description provided for @guideHold.
  ///
  /// In en, this message translates to:
  /// **'Hold a tab to start or stop its sound from any section.'**
  String get guideHold;

  /// No description provided for @guideDrone.
  ///
  /// In en, this message translates to:
  /// **'In Harmony, tap a note to play it. Hold C♯ or F♯ to write them D♭ or G♭.'**
  String get guideDrone;

  /// No description provided for @guideTuner.
  ///
  /// In en, this message translates to:
  /// **'The tuner listens by itself. Going there pauses the metronome and the harmony.'**
  String get guideTuner;

  /// No description provided for @guideVolume.
  ///
  /// In en, this message translates to:
  /// **'The volume is the phone\'s: use its volume keys. The slider at the bottom only balances the metronome and the harmony.'**
  String get guideVolume;

  /// No description provided for @guideDone.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get guideDone;

  /// What holding a key of the drone does: C♯ written as D♭.
  ///
  /// In en, this message translates to:
  /// **'Write as {note}'**
  String writeAs(String note);

  /// No description provided for @aboutSource.
  ///
  /// In en, this message translates to:
  /// **'Source code: {url}'**
  String aboutSource(String url);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
