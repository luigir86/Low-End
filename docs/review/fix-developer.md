# LowEnd: fix dai rapporti di revisione (contrabbassista + UI/UX)

Branch `metronome`. Ho lavorato sopra le modifiche locali già presenti (icona col leone, assets/brand/, design/, about.dart, metronome_screen.dart, widget_test.dart, make_icons_test.dart, pubspec.yaml, rimozione di scroll_mark.dart) e le ho conservate. Niente commit, push, stash, reset o checkout. Niente installazione sul telefono e niente adb.

Prima di correggere ho verificato ogni punto nel codice. Tutti i punti richiesti erano fondati; le eccezioni e i dettagli sono indicati punto per punto.

## Audio e musica

### 1. Tempi composti: BPM sulla semiminima puntata, etichetta, limite, tap. FATTO
- Verificato: in x/8 il BPM contava le crome (`ClickSound.bar` un click per pulsazione), con un massimo di 250 e l'etichetta fissa "BPM".
- `TimeSignature` ha ora `compound` (6/8, 9/8, 12/8: gruppi tutti da 3), `pulsesPerBeat` (3 nei composti, altrimenti 1) e `beatUnit` (♩, ♩. oppure ♪ per il 7/8, i cui gruppi sono irregolari).
- `MetronomeController.bpm` conta la figura della pulsazione. `pulseBpm = bpm × pulsesPerBeat` va al click e al piano. `beatLength` diventa `pulseLength`. In 6/8 a ♩. = 60 si sentono 180 crome al minuto.
- Limite: 30-250 sulla pulsazione, quindi ♩. fino a 250 (cioè ♪ = 750). In 7/8, dove conta la croma, il massimo sale a 400 (`maxEighthBpm`, `maxBpmFor`, `maxTempo`). Cambiando metro il numero resta uguale, ridotto nel nuovo intervallo se serve.
- Etichetta sotto il numero: "♩ BPM", "♪ BPM" in 7/8, e nei composti "♩. BPM · ♪ = 180". TalkBack legge "60 BPM, semiminima puntata". Anche la voce del menu Stile del drone mostra "Segue il metronomo: ♩. = 60, 6/8".
- Tap: con il BPM riferito alla pulsazione, il tap su ogni semiminima puntata dà già il valore giusto, quindi il bug del fattore 3 sparisce. C'è un test apposta.
- Azioni (`app_actions`): il `bpm` viene controllato rispetto al metro corrente e la descrizione spiega la figura. Ho tolto anche "in 4/4" dalla descrizione di `metronome_start`, che era sbagliata. `docs/llm-actions.json` è stato rigenerato.

### 2. Sfasamento piano/click ai cambi di tempo, e accorpamento dei render. FATTO
- Verificato: nel carry-on il piano riprendeva dalla propria fase, e `_sync` del drone metteva in coda un render per ogni passo.
- `BarLoopPlayer('piano', follows: true)`: quando il piano sostituisce il proprio loop in carry-on e il click suona, riparte dalla fase del click (`LoopTransport.phaseOf`). Resta nella stessa battuta, oppure nella successiva o nella precedente se i due si erano spostati oltre la stanghetta (`LoopTransport.followerPosition`). Il click resta il riferimento e non salta.
- `DroneController._sync` accorpa le richieste: c'è al massimo un render in corso e uno in attesa, e quello in attesa legge lo stato più recente quando arriva il suo turno. Tenendo premuto + si fanno al massimo 2 render invece di 20.

### 3. Doppio attacco al cambio di loop, e cambio di metro con entrambi attivi. FATTO
- Verificato: `scheduleStop(old, delay)` conta dal momento della chiamata, mentre `playScheduled` usa il clock del motore.
- Ora il tempo del motore si legge una volta sola (`startsAt = getEngineTime() + wait`): il nuovo loop parte con `playScheduled(startsAt)` e il vecchio si ferma con `stopScheduled(old, startsAt)`, sullo stesso campione.
- Cambio di metro (punto 4 del rapporto, segnalato come "da verificare"): ho confermato nel codice che `untilBarLine` leggeva `getPosition` anche di una voce programmata e non ancora partita. Ora `LoopTransport` salva lo `startsAt` di ogni loop programmato. Finché non è arrivato, le stanghette si contano da quell'istante (`waitForBarLine(untilStart:)`). Così il nuovo piano entra insieme al click in attesa, non una battuta dopo.
- Da verificare sul telefono: l'esito si sente solo sul dispositivo. Ho verificato la logica e i calcoli con test unitari, non con l'audio vero.

### 4. "Accordo a ogni battuta" a tempi lenti. FATTO
- Verificato: l'accordo veniva suonato una sola volta, con campioni di 3,6 s di cui l'ultimo secondo è una dissolvenza.
- `PianoSound.chordStrikes`: se la battuta (o il gruppo, nello stile "a ogni tempo") dura più di 2,4 s, l'accordo viene ribattuto piano (60% del livello). Lo fa il minor numero di volte possibile, distribuito sulle pulsazioni: in 4/4 a 50 BPM sul primo e sul terzo tempo, in 5/4 a 40 su ogni tempo. A 120 BPM resta un solo colpo, come prima.

### 5. Nota tenuta ribattuta a ogni tempo in 3/4, 5/4, 7/8 lenti. FATTO
- Verificato: l'intervallo tra i colpi doveva dividere esattamente le pulsazioni, e con 5 o 7 l'unica possibilità era 1.
- `PianoSound.droneStrikes`: i colpi sono distribuiti in modo uniforme sulla battuta, il più radi possibile (≤ 2,8 s), anche fuori dai tempi. Esempi: 5/4 a 60 → 2 colpi (il secondo tra il 3° e il 4° tempo), 3/4 a 50 → 2 colpi, 7/8 a ♪ = 100 → 2 colpi. Una battuta che non supera 3,5 s riceve ancora un solo colpo.

### 6. Enarmonie nelle progressioni, e Re♭/Sol♭. FATTO
- Verificato: i nomi erano fissi per classe di altezza (Do♯ minore → E♭ø–A♭7–C♯m).
- `pitch.dart`: `letterOf(pc, flat:)` e `spell(pc, lettera, nomi)`. `ProgressionStep.degree` dà il grado (I = 0 … VII = 6). Il drone scrive ogni radice sulla lettera della tonica più il grado: Do♯ minore → D♯ø G♯7 C♯m, Fa♯ minore → G♯ø, Fa♯ I–VI–IV–V → D♯m. Le doppie alterazioni si evitano e al loro posto si usa il nome consueto.
- Re♭/Sol♭: una pressione lunga sul tasto Do♯ o Fa♯ del cerchio cambia la grafia in Re♭ o Sol♭ (e torna indietro), e con essa gli accordi della tonalità (Re♭: D♭ G♭ A♭). Indizio TalkBack: onLongPressHint "Scrivi come Re♭", con vibrazione leggera. Solo questi due tasti sono reversibili. E♭, A♭ e B♭ restano bemolli, come prima.

### 7. Settima della dominante coerente. FATTO
- Verificato: in modalità Accordo il "7" ha sempre la settima, nelle progressioni solo con "7" acceso (blues di default a triadi).
- In progressione `ChordQuality.dominant` ha sempre la settima: V7 nei II–V–I, I–IV–V e I–VI–IV–V, e il blues tutto a settime. Il "7" resta per maj7, m7 e m7♭5 sugli altri gradi. Ho aggiornato commenti e test.

### 8. Distorsione sugli accordi. FATTO
- Verificato: ogni nota a 0,42 × gain, poi un waveshaper `_soft` con la soglia a 0,6.
- `_soft` è stato rimosso. Con `chordGain(n)`, fino a 4 note colpite insieme (triade + radice all'ottava) il livello è invariato; oltre scende come √(4/n), per esempio 0,89 con la settima. Il volume quindi non sale mai. Alla fine, se il picco del loop supera 0,97, tutto il loop viene abbassato in modo lineare con un solo fattore. Niente armonici aggiunti.

### 9. Accordatore: microfono `unprocessed`. FATTO (da verificare sul telefono)
- Verificato: record 7.1.2 / record_android 2.2.0 supportano `AndroidAudioSource.unprocessed` (minSdk 24, quindi l'API c'è). Se l'AudioRecord non si inizializza, l'errore torna a `startStream`.
- `RecordMicInput` prova prima `unprocessed`. Se fallisce passa a `mic`, la sorgente di prima, e la ricorda. Non posso verificare senza il telefono che sull'S20 FE `unprocessed` dia un livello sufficiente: da provare.

## UI/UX

### 10. Lo swipe verso l'Accordatore. FATTO
- Verificato: si fermava tutto e all'uscita ripartiva da solo.
- Arrivando sull'Accordatore (cambio di sezione, non l'apertura di una pagina sopra), drone e metronomo vanno in pausa e compare una SnackBar "In pausa mentre accordi" con l'azione "Riprendi", che fa ripartire solo quello che suonava. All'uscita non riparte nulla da solo. Aprire e chiudere Impostazioni dall'Accordatore non rimette in pausa ciò che si è ripreso apposta (c'è un test).

### 11. Wakelock. FATTO
- `wakelock_plus: ^1.8.1` (ultima stabile risolta da `flutter pub add`). È in `lib/app/screen_awake.dart` (interfaccia `ScreenAwake`, `WakelockScreenAwake`, `FakeScreenAwake` per i test). Lo schermo resta acceso mentre suona il drone o il metronomo, o mentre l'accordatore ascolta. Funziona solo su Android; gli errori vengono registrati e non bloccano. Opzione in Impostazioni non aggiunta (non richiesta).

### 12. Contrasto. FATTO
- Battere 1: nuovo colore `LowEndColors.downbeat` (chiaro #B8440F arancio bruciato, scuro #FFF4E0 bianco caldo), usato per il segmento e per il pallino centrale, più un segmento sempre più spesso (circa +15%, anche da fermo).
- Segmenti spenti: ho verificato che `outline` come riempimento avrebbe reso indistinguibili gli accordi nel drone (`secondary` A47864 contro `outline` 8A7365 = 1,15:1). Per questo ho tenuto il riempimento tenue e aggiunto un bordo `outline` di 1,5 px (`DialGeometry.paintSegment(border:)`) nel metronomo, nel drone e nell'accordatore a riposo. Contrasto del bordo sul disco: 3,53:1 in chiaro e 4,44:1 in scuro. Battere sul disco: 4,30 e 14,0. Battere contro gli altri battiti: 1,87 e 1,57, più la forma. Il test `theme_test.dart` lo verifica.

### 13. Long-press sui tab. FATTO
- Dall'Accordatore, mentre il microfono ascolta, la pressione lunga non avvia il metronomo né il drone (fermarli resta possibile). Con l'accordatore in pausa funziona come prima.
- Indizio: un tooltip "Tieni premuto per avviare o fermare" compare dopo ogni pressione lunga (in modalità manuale: un tooltip normale ruberebbe la pressione lunga al gesto, e per questo era disattivato). L'onLongPressHint di TalkBack c'era già ed è rimasto.

### 14. Stato di riproduzione. FATTO
- Pallino più grande (11 dp invece di 8, con bordo e opacità minima più alta). Sul tab Metronomo, mentre suona, l'icona piena (`Icons.timer`). Semantics: il tab annuncia "In riproduzione" (value). Il badge di M3 non è stato usato: il pallino pulsante esistente, ingrandito, fa la stessa cosa.

### 15. Accordatore: permesso negato e verdetto. FATTO
- Pulsante "Apri impostazioni" (FilledButton) sotto il messaggio. Non c'era né permission_handler né app_settings, quindi ho seguito il meccanismo già in uso (MethodChannel in `MainActivity.kt`): nuovo canale `low_end/app_settings` che apre `ACTION_APPLICATION_DETAILS_SETTINGS`. Tornando nell'app, l'accordatore richiede di nuovo il permesso, come già faceva.
- Verdetto in `headlineSmall` semibold con il colore del verdetto, freccia da 32 dp, più spazio nel centro (flex 6:3:2 invece di 3:1:1).

### 16. Testi. FATTO
- "Accordo a ogni beat" → "Accordo a ogni tempo".
- "In pausa" (accanto al pulsante "Ascolta") → "Accordatore in pausa: tocca Ascolta" (EN "Tuner paused: tap Listen").
- "Tocca per iniziare" → "Tocca per avviare" (coerente con "Avvia il metronomo").
- Lasciati: "Drone", "BPM" e "TAP", termini tecnici d'uso comune (il rapporto stesso considera accettabile "Drone").

## Non fatto / fuori ambito
- Come richiesto: onboarding, layout orizzontale, nuovi metri, voicing e condotta delle parti, compensazione della latenza, funzioni mancanti.
- Nessuna opzione in Impostazioni per il wakelock (non richiesta).
- Nessun fix è stato scartato perché sbagliato. Una sola variazione rispetto alla proposta: nel punto 12 i segmenti spenti hanno un bordo `outline` invece del riempimento `outline` (motivo indicato sopra).

## File toccati
- lib/features/metronome/time_signature.dart, metronome_controller.dart, metronome_screen.dart
- lib/audio/loop_transport.dart, bar_loop_player.dart, piano_output.dart, piano_sound.dart, pitch.dart, mic_input.dart
- lib/features/tuner/drone/drone_controller.dart, drone_panel.dart, harmony.dart
- lib/features/tuner/tuner_panel.dart
- lib/app/low_end_app.dart, home_shell.dart, theme.dart, screen_awake.dart (nuovo)
- lib/widgets/dial.dart, pulsing_dot.dart
- lib/actions/app_actions.dart, docs/llm-actions.json (rigenerato)
- lib/l10n/app_en.arb, app_it.arb e i file generati app_localizations*.dart
- android/app/src/main/kotlin/com/luigir86/low_end/MainActivity.kt
- pubspec.yaml, pubspec.lock (wakelock_plus)

## Test aggiunti o aggiornati
- test/metronome_controller_test.dart: 6/8 a ♩. = 60 → 180 crome e battuta di 2 s; gruppo "compound bars count the dotted quarter" (6/8, 9/8, 12/8 a ♩. = 100 → 300 crome; x/4 e 7/8; tempi veloci e limite 400 in 7/8; tap in 6/8 sulla semiminima puntata; durata della pulsazione).
- test/loop_transport_test.dart (nuovo): riallineamento del piano alla fase del click, anche oltre la stanghetta e con il giro del loop; attesa della stanghetta da una voce che suona e da una programmata non ancora partita.
- test/piano_test.dart: II–V–I con il V7; ribattuta degli accordi nelle battute lente; nota tenuta non ribattuta a ogni tempo (5/4, 3/4, 7/8); normalizzazione lineare (stessa forma, picco ≤ 0,97); `chordGain`; piano a 180 pulsazioni in 6/8; render accorpati tenendo premuto + (≤ 2 invece di 20).
- test/progression_test.dart: V7 anche con "7" spento; blues tutto a settime; triadi negli altri gradi; enarmonie (Do♯ e Fa♯ minore, Fa♯ maggiore, tonalità con i bemolli, Re♭/Sol♭ e solfeggio).
- test/pitch_test.dart: `spell` e `letterOf`.
- test/theme_test.dart: contrasti di bordo, battere e battito acceso, in chiaro e in scuro.
- test/widget_test.dart: pausa sull'Accordatore con SnackBar, nessuna ripresa all'uscita, "Resume" riprende, wakelock acceso e spento; una pagina aperta sopra l'accordatore non rimette in pausa; la pressione lunga non avvia mentre il microfono ascolta, sì con l'accordatore in pausa; hint e valore "Playing" in Semantics; il pulsante "Open settings" chiama il canale.
- test/regression_test.dart: nuovo testo dell'accordatore in pausa.

## Esito dei controlli
- `dart format --output=none --set-exit-if-changed lib test`: OK (60 file, 0 modificati, exit 0).
- `flutter analyze`: OK, "No issues found!".
- `flutter test`: OK, 232 test passati (erano 205 prima delle modifiche).
- `flutter build apk --release`: OK, `build\app\outputs\flutter-apk\app-release.apk` (62,4 MB), in circa 6 minuti. Solo avvisi di Gradle e Java sull'accesso nativo, nessun errore. L'APK non è stato installato.
- Nota: durante i test OneDrive ha bloccato una volta `build\unit_test_assets`; si è risolto con `rm -rf build`.

## Da verificare sul telefono
- Allineamento piano/click tenendo premuto + e cambiando metro con entrambi attivi (punti 2-3).
- Microfono `unprocessed` sull'S20 FE: livello e lettura del Mi grave (punto 9).
- Resa dei colori del battere e dei bordi (punto 12) e SnackBar/tooltip (punti 10, 13).
