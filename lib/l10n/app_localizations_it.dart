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
  String get metronomeDescription =>
      'Metronomo preciso con accenti e suddivisioni.';

  @override
  String get libraryDescription =>
      'Le tue partiture PDF, scalette e annotazioni.';

  @override
  String get tuneMode => 'Accorda';

  @override
  String get droneMode => 'Drone';

  @override
  String get noteLabel => 'Nota';

  @override
  String get octaveLabel => 'Ottava';

  @override
  String get addFifth => 'Aggiungi la quinta';

  @override
  String get addOctave => 'Aggiungi l\'ottava sopra';

  @override
  String get referencePitch => 'La di riferimento';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get play => 'Suona';

  @override
  String get stop => 'Ferma';

  @override
  String frequencyHz(String frequency) {
    return '$frequency Hz';
  }

  @override
  String get lowNoteWarning =>
      'Gli altoparlanti del telefono riproducono a fatica note così gravi. Usa le cuffie o una cassa esterna.';

  @override
  String droneNowPlaying(String note) {
    return 'Drone · $note';
  }

  @override
  String stopSound(String name) {
    return 'Ferma $name';
  }

  @override
  String get droneShortcutHint => 'Studia con drone e clic insieme.';

  @override
  String get audioUnavailable =>
      'Non è stato possibile avviare l\'audio su questo dispositivo.';

  @override
  String get startListening => 'Ascolta';

  @override
  String get stopListening => 'Smetti di ascoltare';

  @override
  String get tunerIdleHint => 'Tocca Ascolta, poi suona una corda alla volta.';

  @override
  String get playAString => 'Suona una corda';

  @override
  String get micPermissionDenied =>
      'Low End ha bisogno del microfono per sentire il tuo basso. Se hai risposto di no, consentilo nelle impostazioni del telefono in App › Low End › Autorizzazioni.';

  @override
  String get micUnavailable =>
      'Non è stato possibile avviare il microfono su questo dispositivo.';

  @override
  String get inTune => 'Intonato';

  @override
  String get flat => 'Calante';

  @override
  String get sharp => 'Crescente';

  @override
  String centsValue(String cents) {
    return '$cents cent';
  }

  @override
  String playingNote(String note) {
    return 'Stai suonando $note';
  }

  @override
  String get tuningLabel => 'Accordatura';

  @override
  String get chromatic => 'Cromatico (qualsiasi nota)';

  @override
  String get doubleBass => 'Contrabbasso';

  @override
  String get electricBass => 'Basso elettrico';

  @override
  String tuningName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'orchestral': 'Orchestrale',
      'solo': 'Solistica',
      'cExtension': 'Estensione al Do',
      'fiveLowB': '5 corde, Si grave',
      'fiveHighC': '5 corde, Do acuto',
      'fourStrings': '4 corde',
      'fiveStrings': '5 corde',
      'sixStrings': '6 corde',
      'dropD': 'Drop D',
      'other': '$id',
    });
    return '$_temp0';
  }
}
