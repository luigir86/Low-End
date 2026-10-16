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
  String get metronomeHint => 'Tocca per avviare';

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
  String get tunerIdleHint => 'Accordatore in pausa: tocca Ascolta';

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
  String get aboutPiano =>
      'Suoni del pianoforte: Salamander Grand Piano di Alexander Holm (pubblico dominio).';

  @override
  String get styleLabel => 'Stile';

  @override
  String get styleHeld => 'Accordo a ogni battuta';

  @override
  String get styleBeat => 'Accordo a ogni tempo';

  @override
  String get styleArpeggio => 'Arpeggio';

  @override
  String styleTempo(String tempo, String signature) {
    return 'Segue il metronomo: $tempo, $signature';
  }

  @override
  String get beatUnitQuarter => 'semiminima';

  @override
  String get beatUnitDottedQuarter => 'semiminima puntata';

  @override
  String get beatUnitEighth => 'croma';

  @override
  String get pausedForTuner => 'In pausa mentre accordi';

  @override
  String get resume => 'Riprendi';

  @override
  String get playing => 'In riproduzione';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeSystem => 'Come il telefono';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get keepScreenOnTitle => 'Tieni lo schermo acceso';

  @override
  String get keepScreenOnSubtitle => 'Mentre suona o l\'accordatore ascolta';

  @override
  String get setTempo => 'Scrivi il tempo';

  @override
  String get optionsLabel => 'Opzioni del suono';

  @override
  String get octaveLabel => 'Ottava della fondamentale';

  @override
  String get shapeLabel => 'Posizione dell\'accordo';

  @override
  String get shapeStacked => 'Impilato';

  @override
  String get shapeClose => 'Vicino';

  @override
  String get shapeRootless => 'Senza fondamentale';

  @override
  String get balanceMetronome => 'Click';

  @override
  String get balanceDrone => 'Pianoforte';

  @override
  String get guideTitle => 'Gesti e scorciatoie';

  @override
  String get guideRing =>
      'Tocca l\'anello del metronomo per avviarlo e fermarlo.';

  @override
  String get guideTempo =>
      'Tocca il numero per scrivere il tempo. Tieni premuto − o + per scorrere a passi di 5 e 10.';

  @override
  String get guideSwipe => 'Scorri a destra e a sinistra per cambiare sezione.';

  @override
  String get guideHold =>
      'Tieni premuto un tab per avviare o fermare il suo suono da qualsiasi sezione.';

  @override
  String get guideDrone =>
      'Nel drone tocca una nota per farla suonare. Tieni premuto Do♯ o Fa♯ per scriverli Re♭ o Sol♭.';

  @override
  String get guideTuner =>
      'L\'accordatore ascolta da solo. Entrando, metronomo e drone vanno in pausa.';

  @override
  String get guideDone => 'Ho capito';

  @override
  String writeAs(String note) {
    return 'Scrivi come $note';
  }

  @override
  String aboutSource(String url) {
    return 'Codice sorgente: $url';
  }
}
