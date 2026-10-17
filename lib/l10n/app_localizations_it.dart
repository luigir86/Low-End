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
  String get harmonyTab => 'Armonia';

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
  String get droneStop => 'Ferma l\'armonia';

  @override
  String get feelLabel => 'Andamento';

  @override
  String get feelStraight => 'Dritto';

  @override
  String get feelSwing => 'Swing';

  @override
  String get progressionLabel => 'Progressione';

  @override
  String get progressionMinorTwoFiveOne => 'II–V–I minore';

  @override
  String get progressionBlues => 'Blues in 12 battute';

  @override
  String get progressionGenreJazz => 'Standard jazz';

  @override
  String get progressionGenreMinorJazz => 'Jazz in tonalità minore';

  @override
  String get progressionGenreRock => 'Rock ’n’ roll';

  @override
  String get progressionGenrePop => 'Pop anni ’50–’60';

  @override
  String get progressionGenreBlues => 'Blues';

  @override
  String progressionLike(String genre, String song) {
    return '$genre, come $song';
  }

  @override
  String get thanksTitle => 'Ringraziamenti';

  @override
  String get thanksInstagram => 'Seguili su Instagram';

  @override
  String get thanksText =>
      'Grazie alla Power Flower Orchestra di Fossano, che ha ispirato e provato quest’app.';

  @override
  String get addSevenths => 'Aggiungi la settima agli accordi';

  @override
  String droneChordDiminished(String note) {
    return '$note diminuito';
  }

  @override
  String get balanceTitle => 'Bilanciamento';

  @override
  String get balanceLabel => 'Bilanciamento tra metronomo e armonia';

  @override
  String balanceValue(String metronome, String drone) {
    return 'Metronomo $metronome%, armonia $drone%';
  }

  @override
  String get referencePitch => 'La di riferimento';

  @override
  String get lowerPitch => 'Abbassa il La di riferimento';

  @override
  String get higherPitch => 'Alza il La di riferimento';

  @override
  String get choosePitch => 'Scegli un La di riferimento standard';

  @override
  String get pitchBaroque => 'Barocco';

  @override
  String get pitchVerdi => 'Verdi';

  @override
  String get pitchConcert => 'Diapason standard';

  @override
  String get pitchOrchestras => 'Orchestre';

  @override
  String referencePitchHint(String note) {
    return 'La frequenza di $note, per l\'accordatore e l\'armonia.';
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
  String get rootOnly => 'Tonica';

  @override
  String get chordLabel => 'Accordo';

  @override
  String get chordMajor => 'Maggiore';

  @override
  String get chordMinor => 'Minore';

  @override
  String get chordSeventh => 'Settima di dominante';

  @override
  String droneChordHalfDiminished(String note) {
    return '$note semidiminuito';
  }

  @override
  String progressionInKey(String name, String key) {
    return '$name in $key';
  }

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
  String get tunerWillPause => 'Ascoltare mette in pausa ciò che suona';

  @override
  String get tunerIdleHint => 'Accordatore in pausa: tocca Ascolta';

  @override
  String get playAString => 'Suona una nota';

  @override
  String get micPermissionDenied =>
      'Low End ha bisogno del microfono per sentire il tuo strumento. Se hai risposto di no, consentilo nelle impostazioni del telefono in App › Low End › Autorizzazioni.';

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
  String get noteNamesSolfege => 'Do Re Mi';

  @override
  String get noteNamesLetters => 'C D E';

  @override
  String get circleLayoutLabel => 'Cerchio dell\'armonia';

  @override
  String get circleLayoutFifths => 'Cerchio delle quinte';

  @override
  String get circleLayoutChromatic => 'In semitoni (Do, Do♯, Re…)';

  @override
  String get aboutTooltip => 'Informazioni su Low End';

  @override
  String get aboutLegalese =>
      'Software libero e open source, distribuito con licenza MIT.';

  @override
  String get aboutDescription =>
      'Metronomo, armonia e accordatore per musicisti. Realizzata da un contrabbassista amatoriale pensando agli amici dell\'orchestra, ma utile a tutti. Low End funziona offline: il microfono si usa solo mentre l\'accordatore ascolta, e nessun suono o dato esce dal telefono.';

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
  String get octaveSpeakerNote =>
      'Le note gravi si sentono poco dall’altoparlante del telefono: usa le cuffie o una cassa, oppure scegli un’ottava più alta.';

  @override
  String get lowRootNote => 'Nota grave: usa cuffie o cassa';

  @override
  String get bassPreset => 'Basso: ottava bassa, tono continuo';

  @override
  String get continuousToneTitle => 'Tono continuo';

  @override
  String get continuousToneSubtitle =>
      'Un suono fisso al posto del pianoforte ribattuto. Sempre attivo nell’ottava 1.';

  @override
  String get octaveNumberingLabel => 'Numeri delle ottave';

  @override
  String get octaveNumberingHint =>
      'Cambia solo il numero dopo il nome della nota: la nota è la stessa.';

  @override
  String get octaveScientific => 'Scientifica (predefinita)';

  @override
  String get octaveItalian => 'Italiana';

  @override
  String octaveExamples(String a4, String e1) {
    return '$a4 = 440 Hz, il Mi grave del basso è $e1';
  }

  @override
  String get tuningChromatic => 'Cromatico';

  @override
  String get tuningInstrument => 'Strumento';

  @override
  String get tuningGuitar => 'Chitarra';

  @override
  String get tuningViolin => 'Violino';

  @override
  String get tuningViola => 'Viola';

  @override
  String get tuningCello => 'Violoncello';

  @override
  String get tuningUkulele => 'Ukulele';

  @override
  String get tuningBass => 'Basso';

  @override
  String tunerString(String number) {
    return 'Corda $number';
  }

  @override
  String tunerHeard(String note) {
    return 'Senti $note';
  }

  @override
  String get swipeHint =>
      'Scorri in alto o in basso sul cerchio o sulle schede per cambiare sezione.';

  @override
  String get gesturesLockedTitle => 'Blocca i gesti';

  @override
  String get gesturesLockedSubtitle =>
      'Per le prove: niente scorrimenti tra le sezioni né pressione lunga sulle schede, e il tocco sulla scheda attiva non ferma più nulla';

  @override
  String get inTuneZoneTitle => 'Accordatore: intonato entro';

  @override
  String get inTuneZoneSubtitle =>
      'Quanto può scostarsi una nota (in cent, centesimi di semitono) e risultare ancora intonata';

  @override
  String get shapeLabel => 'Posizione dell\'accordo';

  @override
  String get shapeStacked => 'Impilato';

  @override
  String get shapeClose => 'Vicino';

  @override
  String get shapeRootless => 'Senza fondamentale';

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
  String get guideSwipeVertical =>
      'Con il telefono in orizzontale, scorri verso l\'alto o il basso sul cerchio o sulle schede per cambiare sezione.';

  @override
  String get guideHold =>
      'Tieni premuto una scheda per avviare o fermare il suo suono da qualsiasi sezione.';

  @override
  String get guideDrone =>
      'In Armonia tocca una nota per farla suonare. Tieni premuto Do♯ o Fa♯ per scriverli Re♭ o Sol♭.';

  @override
  String get guideTuner =>
      'L\'accordatore ascolta da solo. Entrando, metronomo e armonia vanno in pausa.';

  @override
  String get guideVolume =>
      'Il volume è quello del telefono: usa i suoi tasti. Il cursore in basso bilancia solo metronomo e armonia.';

  @override
  String get guideDone => 'Ho capito';

  @override
  String writeAs(String note) {
    return 'Scrivi come $note';
  }

  @override
  String get guidePage1Title => 'Suonare';

  @override
  String get guidePage2Title => 'Muoversi';

  @override
  String get guidePage3Title => 'Accordare e volume';

  @override
  String get guideNext => 'Avanti';

  @override
  String guidePageOf(int n, int total) {
    return 'Pagina $n di $total';
  }

  @override
  String get guideLock =>
      'Per le prove, blocca i gesti dalle impostazioni: anche il tocco sulla scheda attiva non ferma più nulla.';

  @override
  String get guideCents =>
      'Il cent è un centesimo di semitono: entro pochi cent una nota è intonata.';

  @override
  String get progressionBluesShort => 'Blues';

  @override
  String keyLine(String progression, String key) {
    return '$progression in $key';
  }

  @override
  String keySheetTitle(String key) {
    return 'Tonalità: $key';
  }

  @override
  String get degreeName1 => 'Tonica';

  @override
  String get degreeName2 => 'Sopratonica';

  @override
  String get degreeName3 => 'Mediante';

  @override
  String get degreeName4 => 'Sottodominante';

  @override
  String get degreeName5 => 'Dominante';

  @override
  String get degreeName6 => 'Sopradominante';

  @override
  String get degreeName7 => 'Sensibile';

  @override
  String get legendTitle => 'Legenda';

  @override
  String get legendButton => 'Legenda e gradi';

  @override
  String get legendRoot => 'Nota che suona (la fondamentale)';

  @override
  String get legendChord => 'Altre note dell\'accordo che suona';

  @override
  String get legendInKey => 'Note della tonalità';

  @override
  String get legendOutOfKey => 'Note fuori tonalità, sbiadite';

  @override
  String get legendNumerals =>
      'I numeri romani dicono il grado della tonalità su cui poggia ogni accordo. Tocca un numero sul cerchio per leggerlo qui.';

  @override
  String get legendDots =>
      'I pallini sono le battute della progressione: quello pieno è l\'accordo che suona.';

  @override
  String get songsTitle => 'Brani d\'esempio';

  @override
  String get songsSubtitle =>
      'Imposta tonalità, progressione e tempo in un tocco';

  @override
  String get tunerHeld => 'Nota in attesa';

  @override
  String aboutSource(String url) {
    return 'Codice sorgente: $url';
  }
}
