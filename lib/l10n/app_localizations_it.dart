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
  String get droneMode => 'Drone';

  @override
  String get metronomeStart => 'Avvia il metronomo';

  @override
  String get metronomeStop => 'Ferma il metronomo';

  @override
  String get metronomeHint => 'Tocca per iniziare';

  @override
  String bpmValue(String bpm) {
    return '$bpm BPM';
  }

  @override
  String get timeSignature => 'Misura';

  @override
  String get backgroundPlaying => 'In riproduzione in background';

  @override
  String get holdToToggle => 'Tieni premuto per avviare o fermare';

  @override
  String get slower => 'Più lento';

  @override
  String get faster => 'Più veloce';

  @override
  String get tapTempo => 'Batti il tempo';

  @override
  String get droneStop => 'Ferma il drone';

  @override
  String get progressionLabel => 'Progressione';

  @override
  String get progressionMinorTwoFiveOne => 'II–V–I minore';

  @override
  String get progressionBlues => 'Blues in 12 battute';

  @override
  String get addSevenths => 'Aggiungi la settima agli accordi';

  @override
  String degreeOf(String degree, String key) {
    return '$degree di $key';
  }

  @override
  String droneChordDiminished(String note) {
    return '$note diminuito';
  }

  @override
  String get balanceLabel => 'Bilanciamento tra metronomo e drone';

  @override
  String balanceValue(String metronome, String drone) {
    return 'Metronomo $metronome%, drone $drone%';
  }

  @override
  String get referencePitch => 'La di riferimento';

  @override
  String referencePitchHint(String note) {
    return 'La frequenza di $note, per l\'accordatore e il drone.';
  }

  @override
  String frequencyHz(String frequency) {
    return '$frequency Hz';
  }

  @override
  String stopSound(String name) {
    return 'Ferma $name';
  }

  @override
  String playSound(String name) {
    return 'Suona $name';
  }

  @override
  String get droneHint =>
      'Tocca una nota per farla suonare. Toccala di nuovo per fermarla.';

  @override
  String get rootOnly => 'Fondamentale';

  @override
  String get chordLabel => 'Accordo';

  @override
  String get chordMajor => 'Maggiore';

  @override
  String get chordMinor => 'Minore';

  @override
  String get chordSeventh => '7';

  @override
  String droneChordMajor(String note) {
    return '$note maggiore';
  }

  @override
  String droneChordMinor(String note) {
    return '$note minore';
  }

  @override
  String droneChordSeventh(String note) {
    return '${note}7';
  }

  @override
  String get audioUnavailable =>
      'Non è stato possibile avviare l\'audio su questo dispositivo.';

  @override
  String get startListening => 'Ascolta';

  @override
  String get stopListening => 'Pausa';

  @override
  String get tunerIdleHint => 'In pausa';

  @override
  String get playAString => 'Suona una nota';

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
  String get settingsTitle => 'Impostazioni';

  @override
  String get languageLabel => 'Lingua';

  @override
  String get languageSystem => 'Come il telefono';

  @override
  String get noteNamesLabel => 'Nomi delle note';

  @override
  String get noteNamesAuto => 'Come la lingua';

  @override
  String get noteNamesSolfege => 'Do Re Mi (La3 = 440 Hz)';

  @override
  String get noteNamesLetters => 'C D E (A4 = 440 Hz)';

  @override
  String get aboutTooltip => 'Informazioni su Low End';

  @override
  String get aboutLegalese =>
      'Software libero e open source, distribuito con licenza MIT.';

  @override
  String get aboutDescription =>
      'Accordatore, drone e metronomo per contrabbasso e basso elettrico. Low End funziona offline: il microfono si usa solo mentre l\'accordatore ascolta, e nessun suono o dato esce dal telefono.';

  @override
  String aboutSource(String url) {
    return 'Codice sorgente: $url';
  }
}
