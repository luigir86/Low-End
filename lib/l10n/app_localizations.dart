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

  /// No description provided for @libraryTab.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTab;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @metronomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Precise metronome with accents and subdivisions.'**
  String get metronomeDescription;

  /// No description provided for @libraryDescription.
  ///
  /// In en, this message translates to:
  /// **'Your PDF scores, set lists and annotations.'**
  String get libraryDescription;

  /// No description provided for @tuneMode.
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get tuneMode;

  /// No description provided for @droneMode.
  ///
  /// In en, this message translates to:
  /// **'Drone'**
  String get droneMode;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @octaveLabel.
  ///
  /// In en, this message translates to:
  /// **'Octave'**
  String get octaveLabel;

  /// No description provided for @addFifth.
  ///
  /// In en, this message translates to:
  /// **'Add the fifth'**
  String get addFifth;

  /// No description provided for @addOctave.
  ///
  /// In en, this message translates to:
  /// **'Add the octave above'**
  String get addOctave;

  /// No description provided for @referencePitch.
  ///
  /// In en, this message translates to:
  /// **'Reference A'**
  String get referencePitch;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @frequencyHz.
  ///
  /// In en, this message translates to:
  /// **'{frequency} Hz'**
  String frequencyHz(String frequency);

  /// No description provided for @lowNoteWarning.
  ///
  /// In en, this message translates to:
  /// **'Phone speakers can barely play notes this low. Use headphones or an external speaker.'**
  String get lowNoteWarning;

  /// No description provided for @droneNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Drone · {note}'**
  String droneNowPlaying(String note);

  /// No description provided for @stopSound.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}'**
  String stopSound(String name);

  /// No description provided for @droneShortcutHint.
  ///
  /// In en, this message translates to:
  /// **'Practise with the drone and the click together.'**
  String get droneShortcutHint;

  /// No description provided for @audioUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sound could not start on this device.'**
  String get audioUnavailable;

  /// No description provided for @startListening.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get startListening;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get stopListening;

  /// No description provided for @tunerIdleHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Start listening, then play one string at a time.'**
  String get tunerIdleHint;

  /// No description provided for @playAString.
  ///
  /// In en, this message translates to:
  /// **'Play a string'**
  String get playAString;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Low End needs the microphone to hear your bass. If you said no, allow it in the phone settings under Apps › Low End › Permissions.'**
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

  /// No description provided for @playingNote.
  ///
  /// In en, this message translates to:
  /// **'You are playing {note}'**
  String playingNote(String note);

  /// No description provided for @tuningLabel.
  ///
  /// In en, this message translates to:
  /// **'Tuning'**
  String get tuningLabel;

  /// No description provided for @chromatic.
  ///
  /// In en, this message translates to:
  /// **'Chromatic (any note)'**
  String get chromatic;

  /// No description provided for @doubleBass.
  ///
  /// In en, this message translates to:
  /// **'Double bass'**
  String get doubleBass;

  /// No description provided for @electricBass.
  ///
  /// In en, this message translates to:
  /// **'Electric bass'**
  String get electricBass;

  /// No description provided for @tuningName.
  ///
  /// In en, this message translates to:
  /// **'{id, select, orchestral{Orchestral} solo{Solo} cExtension{C extension} fiveLowB{5 strings, low B} fiveHighC{5 strings, high C} fourStrings{4 strings} fiveStrings{5 strings} sixStrings{6 strings} dropD{Drop D} other{{id}}}'**
  String tuningName(String id);
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
