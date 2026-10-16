# LowEnd: revisione dal punto di vista di un contrabbassista

Revisione fatta solo leggendo il codice (branch `metronome`, con le modifiche locali non committate). Non ho toccato file, non ho fatto build e non ho eseguito l'app. Ogni punto rimanda a file e righe. Dove un comportamento dipende dal dispositivo o dal motore audio e non si ricava dal solo codice, lo segnalo come **da verificare**.

Legenda priorità: **P1** = bug musicale concreto che si sente o si vede suonando; **P2** = limite serio per lo studio o il palco; **P3** = miglioramento o funzione mancante.

---

## P1: bug musicali concreti

### 1. Metronomo: nei tempi in ottavi il BPM conta le crome, con tetto a 250, e non lo dice
- **Problema.** In x/8 il tempo conta gli ottavi (`time_signature.dart:4-8`, `click_sound.dart:51`: un click per pulsazione). Il massimo è 250 (`metronome_controller.dart:20`), quindi in 6/8, 9/8 e 12/8 la semiminima puntata arriva al massimo a 83. Lo schermo mostra solo "BPM" (`metronome_screen.dart:280-292`), senza dire quale figura conta.
- **Perché conta.** Una giga, una tarantella o un 6/8 afro-cubano (bembé) a semiminima puntata = 100-120 vogliono 300-360 crome: non si possono impostare. E chi imposta "60" in 6/8 pensando alla semiminima puntata (l'uso normale) si ritrova la semiminima puntata a 20. Lo stesso vale per un 7/8 balcanico veloce.
- **Correzione.** Mostrare la figura dell'unità (♩ = / ♪ = / ♩. =) e lasciar scegliere se il tempo si riferisce alla pulsazione o al gruppo (in 6/8: ♩. = 60 dà ♪ = 180). Internamente basta convertire. In alternativa, alzare `maxBpm` almeno a 400 per i tempi in ottavi.

### 2. Il tap tempo nei tempi composti sbaglia di un fattore 3
- **Problema.** `tap()` (`metronome_controller.dart:168-176`) fissa il BPM sull'intervallo tra i tap. In 6/8 chiunque batte la semiminima puntata, ma il valore viene preso come croma, quindi il tempo risulta tre volte più lento.
- **Correzione.** In un tempo raggruppato (`signature.grouped`), interpretare il tap come inizio di gruppo e moltiplicare per la lunghezza del gruppo. Si risolve insieme al punto 1.

### 3. Pianoforte e click si sfasano dopo ogni cambio di tempo, e non si riallineano più
- **Problema.** Quando cambia il BPM, il click ricostruisce subito il suo loop "carry on" (`metronome_controller.dart:117-125` → `bar_loop_player.dart:49-61`). Il piano invece ricostruisce il suo loop dopo il rendering in un isolate (`piano_output.dart:61-72`, `PianoSound.loop`). Nel frattempo il vecchio loop del piano continua al tempo vecchio, mentre il click va già al nuovo. Al momento dello scambio, il piano riprende dalla *propria* fase (`bar_loop_player.dart:53-61`), non da quella del click. Il `LoopTransport` serve solo per le partenze "dall'uno" (`bar_loop_player.dart:50`), mai nel carry-on. Lo sfasamento vale circa `latenza_render × (1/battuta_vecchia − 1/battuta_nuova)` e si somma a ogni cambio.
- **Stima.** Da 100 a 200 BPM tenendo premuto + (20 passi da 5), con 0,3 s di render a passo: circa 1/8 di battuta, cioè circa 150 ms in 4/4 a 200. È un flam ben udibile tra il piano e il click.
- **Aggravante.** Il `_sync` del drone non accorpa le richieste: ogni passo mette in coda un render completo (`drone_controller.dart:412-421`, `_onClockChanged` 372-380). Il metronomo invece le accorpa (`metronome_controller.dart:189-203`). Tenendo premuto + per 2 s, il piano rincorre per parecchi render, uno dopo l'altro, fino al 12-bar blues che è il più lungo.
- **Correzione.** (a) In carry-on, se l'altro loop suona, calcolare la posizione del nuovo loop dalla fase del click: `fase_click × battuta_nuova + indice_battuta × battuta_nuova`, invece di partire dalla propria fase. In pratica si estende `LoopTransport` con una `phaseOf(other)`. (b) Accorpare le `_sync` del drone come fa il metronomo, rendendo solo l'ultimo stato.

### 4. Cambio di metro con piano e click insieme: possibile partenza sfasata (da verificare)
- **Problema.** Al cambio di metro ripartono entrambi "dall'uno". Il click aspetta la prossima stanghetta del piano *vecchio* e si programma con `playScheduled` (`bar_loop_player.dart:72-82`). Il piano, finito il render, chiede `untilBarLine('piano')`, che legge `getPosition` del nuovo click, ancora in attesa e non partito (`loop_transport.dart:35-42`). Se una voce programmata ma non ancora partita riporta posizione 0, il piano entra a "ora + una battuta" mentre il click entra a "ora + attesa residua": i due restano sfasati di quell'attesa.
- **Correzione.** Tenere in `LoopTransport` l'istante programmato (engine time) di ogni loop e calcolare le stanghette da lì, non da `getPosition`.

### 5. Doppio attacco al passaggio tra vecchio e nuovo loop
- **Problema.** Il nuovo loop parte a `getEngineTime() + wait` (`bar_loop_player.dart:78`), ma il vecchio si ferma con `scheduleStop(old, delay)` (riga 90), che secondo la documentazione di flutter_soloud 5.2.1 "measures from call time". Il vecchio si ferma quindi un po' *dopo* la stanghetta e fa partire il proprio "uno" sopra quello nuovo: un flam o un click doppio sul primo tempo.
- **Correzione.** Usare `stopScheduled(old, engineTimeLetto + wait)`, con lo stesso istante assoluto usato per `playScheduled`.

### 6. "Accordo a ogni battuta" a tempi lenti: l'accordo si spegne prima della fine della battuta
- **Problema.** I campioni durano 3,6 s e l'ultimo secondo è una dissolvenza (`assets/piano/README.md`, `tool/prepare_piano.dart:21-23,116-119`). Nello stile `bar` l'accordo viene suonato una sola volta (`piano_sound.dart:197-203`) e `sounding = min(length, hold+release)` (riga 149). Sotto circa 67 BPM in 4/4 (sotto circa 50 in 3/4, sotto circa 45 in 5/4) la fine della battuta resta muta, e la dissolvenza comincia già dopo circa 2,6 s. Lo stesso succede nello stile `beat` per i gruppi lunghi (12/8 lento: gruppo di 3 crome a 40 BPM = 4,5 s). I test coprono solo 240 BPM (`test/piano_test.dart:105-118`).
- **Perché conta.** Ballad, studio lento dell'intonazione e scale a 50-60: proprio dove il drone serve di più.
- **Correzione.** Se la battuta (o il gruppo) supera circa 2,5 s, ribattere l'accordo piano (velocity bassa) a metà battuta o su ogni gruppo, oppure fare un loop di sustain sulla coda del campione con crossfade.

### 7. "Nota sola tenuta": in 3/4, 5/4, 7/8 e 9/8 lenti viene ribattuta a ogni pulsazione
- **Problema.** Nello stile `drone` (`piano_sound.dart:183-196`) l'intervallo tra i colpi deve essere un *divisore* del numero di pulsazioni, al massimo 2,8 s. Con 5 o 7 pulsazioni (numeri primi) o con 3 lente, l'unico divisore utile è 1: la nota viene ribattuta a ogni pulsazione. Esempi: 5/4 a 60, 3/4 a 50, 7/8 a 100. Il commento della classe promette "no beat to it" (righe 11-13).
- **Perché conta.** Una nota tenuta con un attacco di pianoforte a ogni tempo non è un bordone: per l'intonazione delle note lunghe gli attacchi disturbano.
- **Correzione.** Ribattere con intervallo libero (anche non allineato ai tempi, per esempio ogni 2,5 s con crossfade), oppure usare per la "Fondamentale" il suono sintetico continuo che esiste già (`DroneSound`/`SoLoudToneOutput`, `tone_output.dart`), che in produzione non viene mai usato (`drone_controller.dart:426-428`).

### 8. Enarmonie sbagliate negli accordi delle progressioni
- **Problema.** I nomi delle note sono fissi per classe di altezza (`pitch.dart:21-27`: C♯, E♭, F♯, A♭, B♭), e gli accordi delle progressioni prendono il nome dalla radice con quella grafia (`drone_panel.dart:340`, `chordSymbol` 410-424). Così, nella stessa progressione:
  - II–V–I minore in **Do♯ minore** dà E♭ø – A♭7 – C♯m (deve essere D♯ø – G♯7 – C♯m);
  - in **Fa♯ minore** dà A♭ø – C♯7 – F♯m (deve essere G♯ø);
  - I–VI–IV–V in **Fa♯** dà F♯ – E♭m – B – C♯ (deve essere D♯m);
  - in **Re♭** non si può scegliere: compare C♯, con IV = F♯ (deve essere G♭) e V = A♭.
- **Perché conta.** Chi legge un real book in Re♭ o Do♯ minore trova sigle diverse da quelle sulla parte. Sono tonalità comuni (Body and Soul in Re♭).
- **Correzione.** Scrivere ogni grado in base alla tonalità: lettera della tonica + numero di gradi della scala, poi l'alterazione. Permettere di scegliere C♯/D♭ e F♯/G♭ sul cerchio, per esempio con una pressione lunga o seguendo l'ultima tonalità scelta.

### 9. Il blues e il V delle progressioni sono triadi se "7" è spento
- **Problema.** In progressione la settima c'è solo con l'interruttore "7" acceso (`drone_controller.dart:182-186`: `seventh: _sevenths`). Il blues in 12 battute, "all dominant" secondo il commento (`harmony.dart:86`), suona di default triadi maggiori; in II–V–I il V è una triade. In modalità Accordo invece il "7" dominante ha sempre la settima (`drone_controller.dart:180`).
- **Correzione.** Per `ChordQuality.dominant` in progressione, mettere sempre la settima (come in modalità Accordo), o almeno nel blues. Lasciare "7" per maj7/m7/ø sugli altri gradi.

---

## P2: limiti seri per lo studio o il palco

### 10. Voicing del piano: sempre in stato fondamentale, nell'ottava Do4-Si4, senza condotta delle parti
- **Problema.** Ogni accordo parte dalla radice in ottava 4 (`drone_controller.dart:100, 383-402`) più la radice un'ottava sotto (`piano_sound.dart:196, 203, 214`). In II–V–I in Do: Re4-Fa-La → Sol4-Si-Re5 → Do4-Mi-Sol, con salti di quinta e quarta tra gli accordi e registro diverso a seconda della tonalità (in Si l'accordo di Si sta in alto, il suo V Fa♯ sta sotto).
- **Perché conta.** Non suona come un pianista che accompagna. Inoltre la radice raddoppiata (Do3-Si3) copre proprio la nota che il contrabbassista deve suonare: per la walking e per l'orecchio armonico si studia su voicing **senza fondamentale** (3ª e 7ª, "rootless" tipo A/B).
- **Correzione.** Scegliere per ogni accordo il rivolto più vicino al precedente dentro un range fisso (per esempio Mi3-Re5), e aggiungere un'opzione "senza fondamentale" (3-7 o 3-5-7-9).

### 11. Intonazione: il codice dice "intervalli giusti", ma in produzione il piano suona temperamento equabile
- **Problema.** `harmony.dart:1-3` e i rapporti 5/4, 6/5, 16/9 descrivono un drone in intonazione giusta, ma i rapporti servono solo al fallback sintetico (usato nei test, vedi `low_end_app.dart:60-64`). Il piano usa semitoni equabili (`drone_controller.dart:392`, `piano_sound.dart:143-147`). Per di più i campioni Salamander sono trasposti fino a ±1 semitono con rapporti nominali (`piano_sound.dart:140-147`) e non vengono verificati né corretti in altezza (`tool/prepare_piano.dart` non misura l'intonazione). Ereditano quindi l'accordatura reale del Yamaha C5, con lo stretch e qualche cent di scarto nota per nota (**da verificare** misurando i 14 campioni).
- **Perché conta.** Per l'intonazione di terze e seste su un bordone (lavoro classico tipico) il musicista vuole sapere se sta suonando contro un ET o contro intervalli puri, e il riferimento deve essere esatto al cent.
- **Correzione.** Misurare l'altezza di ogni campione (YIN già presente) e salvare una correzione in cent per campione. Offrire un'opzione "intonazione giusta" che usi i `ratios()` già presenti, sul piano (step per nota) o sul suono sintetico. Correggere i commenti.

### 12. Possibile distorsione degli accordi con il soft-clip (da verificare)
- **Problema.** Ogni nota entra a 0,42 × gain (`piano_sound.dart:93, 173`). Con 4 note più la radice all'ottava, più le code che si sovrappongono nello stile `beat`, la somma supera facilmente la soglia di 0,6 del waveshaper `_soft` (righe 225-227, 261-267). Un waveshaper aggiunge armonici e intermodulazione: sugli accordi produce battimenti spuri, proprio quello che disturba chi controlla l'intonazione.
- **Correzione.** Normalizzare il loop con un guadagno lineare unico (picco → −1 dBFS) dopo il mix e tenere `_soft` solo come protezione estrema.

### 13. Registro del drone fisso in ottava 4, nessuna scelta di ottava
- **Problema.** `DroneController.octave = 4` (`drone_controller.dart:98-100`); le azioni ignorano l'ottava (`app_actions.dart:74-80`).
- **Perché conta.** Per l'intonazione sul contrabbasso si lavora meglio con il bordone all'unisono o all'ottava della nota suonata (ottave 1-3): i battimenti si sentono molto più chiaramente. In cuffia o con un amplificatore il registro basso è riproducibile. Il Si (Si4) e il Do (Do4) sono anche lontani tra loro: i tasti più "alti" del cerchio suonano quasi un'ottava sopra i vicini.
- **Correzione.** Selettore di ottava (2/3/4) per la fondamentale. Default 3 con l'avviso di usare le cuffie sotto un certo registro.

### 14. Accordatore: con le corde preimpostate, armonici ed errori d'ottava danno letture assurde (latente)
- **Problema.** Le accordature (orchestrale, solista F♯1 B1 E2 A2, prolunga Do, 5 corde: sono corrette, `tunings.dart:29-42`) non sono esposte nell'interfaccia: l'accordatore è solo cromatico (`tuner_panel.dart:16-17`; `setTuning` non viene chiamato da nessuna parte). Ma `TunerReading.of` (`tunings.dart:50-62`) sceglie la corda più vicina *in cent assoluti*. Il giorno in cui le corde si mostrano, l'armonico all'ottava del Sol (Sol3, 196 Hz, il modo classico di accordare il contrabbasso) verrebbe letto come "Sol2 +1200 cent". Lo stesso vale per un errore d'ottava di YIN sul Mi1 (letto Mi2 → "Re2 +200").
- **In cromatico.** Un errore d'ottava cambia solo il numero d'ottava, non i cent, quindi l'accordatura resta corretta.
- **Correzione.** In modalità corde, confrontare per classe di altezza (ripiegando le ottave) e mostrare "armonico n" quando la frequenza è un multiplo intero della corda.

### 15. Accordatore: microfono "MIC" con l'elaborazione del telefono, e test troppo ottimisti sul Mi grave
- **Problema.** `AndroidAudioSource.mic` (`mic_input.dart:41`) su molti telefoni applica un filtro passa-alto e altre elaborazioni anche con autoGain, echoCancel e noiseSuppress spenti. Il record 7 offre `AndroidAudioSource.unprocessed` (API 24+). Il test della fondamentale debole usa ancora un'ampiezza del 30% (`test/pitch_detector_test.dart:35-40`), mentre un microfono MEMS a 41 Hz attenua di 20-30 dB.
- **Correzione.** Provare `unprocessed`, con fallback a `voiceRecognition`. Aggiungere un test con la fondamentale a 0,03 e gli armonici pari dominanti, verificando che il primo minimo sotto 0,15 non cada a T/2 (`pitch_detector.dart:80-87`). Se succede, controllare il minimo a 2×lag prima di accettare il primo.

### 16. Lo schermo del metronomo anticipa il suono (latenza di uscita non compensata)
- **Problema.** L'anello e il punto seguono uno `Stopwatch` (`metronome_controller.dart:15-17, 71-77`) azzerato quando il loop parte, senza tenere conto della latenza di uscita (flutter_soloud offre `getOutputLatency`/`getPlayheadTime` solo con il render-ahead attivo, che qui non viene usato: `soloud_engine.dart:10`). Su Android il flash anticipa il click di circa 20-100 ms, e con le cuffie Bluetooth di 150-300 ms.
- **Inoltre.** `beatLength` è in µs troncati (riga 64), mentre l'audio usa campioni arrotondati (`click_sound.dart:51`), e il clock di sistema non è quello del DAC: su sessioni lunghe la grafica deriva di qualche ms, mentre l'audio resta esatto.
- **Correzione.** Ricavare la fase dalla posizione del loop audio (`getPosition` del click, o `getPlayheadTime` con render-ahead) e aggiungere un offset di latenza impostabile ("calibra Bluetooth").

### 17. Tuner e suoni si escludono a vicenda
- **Problema.** Aprendo la scheda Accordatore, drone e metronomo si fermano (`low_end_app.dart:128-145`).
- **Perché conta.** È giusto con l'altoparlante, ma impedisce il classico esercizio "scala lenta sul bordone guardando l'accordatore" e il controllo dell'intonazione a tempo. In cuffia funzionerebbe.
- **Correzione.** Mostrare una piccola lettura del tuner dentro la schermata Drone, o un'opzione "non fermare con le cuffie collegate".

---

## P3: funzioni che un contrabbassista si aspetta

### 18. Metronomo
- **Accenti su 2 e 4 / "jazz"**: oggi l'"uno" ha sempre l'accento a 1000 Hz (`click_sound.dart:13-17, 55-61`) e non si possono silenziare dei tempi. Per il jazz è la funzione più richiesta (anche "solo 4" a metà tempo).
- **Suddivisioni**: crome, terzine, semicrome, swing. Assenti.
- **Metri mancanti**: 2/2 (alla breve, ovunque nel repertorio orchestrale), 3/8, 6/4, 3/2, 5/8 (`time_signature.dart:19-37`).
- **Raggruppamenti alternativi**: 5/4 è fisso 3+2, 7/8 è fisso 2+2+3. Mancano 2+3, 3+2+2 e 2+3+2. Attenzione: `operator ==` confronta solo numeratore e denominatore (`time_signature.dart:62-66`), quindi due 7/8 con gruppi diversi risulterebbero uguali. Va corretto prima di aggiungerli.
- **Range**: 30-250 (`metronome_controller.dart:19-20`). Il bebop veloce supera 300, e lo studio lentissimo vuole 20 (oppure 40 col click ogni 2).
- **Trainer**: battute mute ("gap"), accelerazione automatica di N BPM ogni X battute, conteggio iniziale.
- **Memoria**: tempo, metro, stile del drone e progressione non vengono salvati (`settings.dart:14-30` salva solo lingua, nomi, La e bilanciamento). Mancano anche preset o scalette per il palco.
- **Partenza in attesa**: con il piano in corso, il metronomo aspetta la stanghetta (`bar_loop_player.dart:50, 72-82`). A 40 BPM in 4/4 sono fino a 6 s di silenzio senza segnale visivo (`barPhase` è null, `metronome_controller.dart:72-74`). Mostrare un conto alla rovescia.
- La descrizione dell'azione `metronome_start` dice "in 4/4" (`app_actions.dart:129`), ma usa il metro corrente; inoltre le azioni non permettono di impostare il metro.

### 19. Drone
- **Progressioni utili mancanti**: I–VI–II–V (turnaround), III–VI–II–V, blues minore, blues "quick change", rhythm changes, giro di quinte (Autumn Leaves), II–V a 2 battute per accordo (`harmony.dart:56-100`: un accordo per battuta, fisso). Servirebbe la durata in battute per ogni accordo.
- **Accordi mancanti** (`drone_controller.dart:31-41`): dim7, m7♭5 in modalità Accordo, sus4, 6 e m6, mMaj7. Il minore con 7 dà sempre m7 (per il I minore nel jazz spesso m6 o mMaj7).
- **Arpeggi**: in 6/8, 9/8 e 12/8 l'arpeggio riparte dalla radice a ogni gruppo di 3, quindi la settima non si sente mai; in 3/4 e 7/8 nemmeno (in 2/4 neanche la quinta) (`piano_sound.dart:246-258`). Proporre l'arpeggio continuo sulle 4 note, o 1-3-5-7 su più battute.
- **Etichette dei gradi**: "II di Do" nel II–V–I minore non dice che la tonalità è minore, e i gradi minori sono maiuscoli (`harmony.dart:59-68`, `drone_panel.dart:346-349`). Meglio "IIø–V7–i in Do minore" oppure "ii–V–I".

### 20. Accordatore
- **Riferimento La** solo 438-445 Hz (`pitch.dart:5-7`). Mancano 415 (barocco, violone), 430 e 432 (classico e storico), 435. Mancano anche i passi da 0,5 Hz, utili con certe orchestre (442,5).
- **Accordature mancanti** (quando verranno mostrate): in quinte Do1-Sol1-Re2-La2 (Red Mitchell, Quarrington); 5 corde orchestrale con Do grave (Do1-Mi1-La1-Re2-Sol2, comune in Germania); solista con prolunga.
- **Soglia "intonato" ±5 cent** (`tunings.dart:65`): per le corde a vuoto un contrabbassista vuole ±2-3. Utile renderla regolabile.
- **Stabilità**: c'è solo la mediana di 3 letture (`tuner_controller.dart:183-186`), nessuna media mobile sui cent. Lo strobo assorbe bene il tremolio, ma il numero dei cent può saltare. Aggiungere un filtro esponenziale leggero sui cent mostrati.
- **Tempi di risposta**: finestra 1716 campioni a 16 kHz (107 ms, 3 periodi a 28 Hz), una lettura ogni 50 ms più la mediana: circa 150-200 ms. Va bene. La frequenza di 16 kHz basta, ma a 700 Hz il periodo è di circa 23 campioni: per gli armonici acuti 44,1 o 48 kHz darebbero più precisione (`tuner_controller.dart:13`, `pitch_detector.dart:37-41`).
- **Ottave in solfeggio**: La3 = 440 (`pitch.dart:14-16, 61-62`) è la convenzione franco-italiana ed è corretta, ma il Mi grave del contrabbasso appare come "Mi0". Molti bassisti ragionano sull'altezza *scritta* (un'ottava sopra). Un'opzione "mostra altezza scritta (+8va)" eviterebbe confusione.

---

## Cosa funziona bene (da non toccare)
- Click e piano come loop di battute intere nel motore audio: nessun jitter del Dart sul tempo, con le battute del piano multiple esatte di quella del click (`click_sound.dart:51`, `piano_sound.dart:133-135`).
- Accordature preimpostate corrette (orchestrale, solista un tono sopra, prolunga Do, Si grave, Do acuto) e `minFrequency` 28 Hz per il Si0.
- YIN con soglia di "hold" per seguire la corda che si spegne, e scarto dei suoni sopra 700 Hz (`pitch_detector.dart:80-104`).
- Raggruppamenti del 6/8 come 3+3 con accento di gruppo, e piano "a ogni beat" che in ottavi batte sul gruppo (`piano_sound.dart:204-214`).
- Tap su pointer-down (`metronome_screen.dart:471-473`) e +/− a scatti su multipli di 5 e 10.
- Voice processing disattivato sul microfono (`mic_input.dart:36-39`).
