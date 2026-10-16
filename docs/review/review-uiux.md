# LowEnd: revisione UI/UX

Branch `metronome`, con le modifiche locali non committate. Revisione **solo del codice** (lib/, test/) e degli asset del brand. Il telefono (S20 FE, `com.luigir86.low_end`) risponde ad adb, ma lo schermo era spento (`mWakefulness=Dozing`). Per svegliarlo servirebbe un `keyevent` o lo sblocco, che non rientrano nei comandi consentiti, quindi non ho screenshot reali dell'app. I valori di contrasto sono calcolati a mano dalla palette in `lib/app/theme.dart` e sono approssimati.

Legenda priorità: **P0** blocca o confonde durante l'uso reale (palco, sala prove) · **P1** problema importante · **P2** rifinitura.

---

## P0. Problemi che bloccano o confondono

### 1. Uno swipe verso l'Accordatore ferma la musica, e uscendone la fa ripartire da sola
- **Problema:** se si arriva sul tab Accordatore, con uno swipe o con un tap, drone e metronomo vengono fermati senza alcun avviso. Quando si lascia il tab ripartono in automatico. Il PageView rende questo passaggio facilissimo: dal Drone basta uno swipe a sinistra.
- **Impatto:** sul palco, uno swipe involontario (per esempio mentre si tocca lo slider di bilanciamento) toglie il click alla band. Tornando indietro il suono riparte all'improvviso, fuori tempo. L'unico segnale è il pallino sui tab che sparisce.
- **Dove:** `lib/app/low_end_app.dart:128-145` (`_onNavigationChanged`), `lib/app/home_shell.dart:125-131` (PageView con la fisica di default).
- **Correzione:**
  - Il cambio di tab non deve fermare l'audio. Il microfono può partire comunque, oppure l'accordatore mostra un banner tipo `MaterialBanner`/`Card` "Il metronomo sta suonando: il microfono lo sentirà" con un pulsante `FilledButton.tonal("Metti in pausa")`.
  - In alternativa, se si vuole tenere la pausa automatica, mostrare `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Metronomo in pausa mentre accordi'), action: SnackBarAction(label: 'Continua', ...)))`. Al ritorno non far ripartire nulla da solo, ma offrire "Riprendi".
  - Valutare `PageView(physics: const NeverScrollableScrollPhysics())` mentre qualcosa suona, oppure una `ScrollPhysics` personalizzata che non permette di scivolare oltre il Drone verso l'Accordatore.

### 2. Lo schermo si spegne durante l'esecuzione
- **Problema:** in tutto il progetto non c'è nessun wakelock (`wakelock_plus`, `FLAG_KEEP_SCREEN_ON`). Il grep su lib/ e android/ non trova nulla.
- **Impatto:** con il telefono sul leggio, dopo il timeout di sistema (30 s / 1 min) l'anello dei battiti scompare. L'audio continua grazie al servizio in background, ma per cambiare BPM bisogna sbloccare il telefono con le mani sullo strumento. Per un metronomo o un accordatore "visivo" è un problema bloccante.
- **Dove:** `lib/app/low_end_app.dart:161-173` (il punto in cui si sa già se qualcosa suona); `lib/features/tuner/tuner_panel.dart:38-43`.
- **Correzione:** aggiungere `wakelock_plus` e chiamare `WakelockPlus.toggle(enable: playing || _navigation.tunerVisible)` dentro `_onPlayingChanged` e `_onNavigationChanged`. Aggiungere poi un'opzione in Impostazioni, "Tieni lo schermo acceso mentre suona" (`SwitchListTile`, attiva di default).

### 3. Nel tema scuro il "battere" (beat 1) si distingue appena dagli altri battiti
- **Problema:** il segmento del beat 1 usa `colorScheme.tertiary`, gli altri `primary`. In tema scuro sono `brassLight #E3C27A` e `mochaLight #E2BFA9`: luminanza e tinta quasi uguali. In tema chiaro sono `brass #7A5C1E` e `walnut #5A3A2A`, due marroni scuri. Il pallino centrale ha lo stesso problema in chiaro (`tertiary` contro `secondary`).
- **Impatto:** nella visione periferica, sul palco buio, non si capisce dov'è l'"uno" della battuta. Sui metronomi è l'informazione più importante.
- **Dove:** `lib/features/metronome/metronome_screen.dart:207-217`, `:235-239`; `lib/app/theme.dart:35`, `:45`, `:148`.
- **Correzione:** dare all'accento un colore dedicato con forte contrasto di luminanza, per esempio un'estensione `LowEndColors.accentBeat` (un bianco caldo `#FFF4E0` in scuro e un rosso o arancio saturo in chiaro). Distinguerlo anche per forma, non solo per colore: il segmento 1 più spesso (`inner: dial.ringInner - dial.ringWidth*0.08`) oppure un breve flash del disco di sfondo sul battere (`background` interpolato nel painter quando `beat == 0 && since < 80ms`).

### 4. Gli anelli da fermi sono quasi invisibili (contrasto dei segmenti spenti)
- **Problema:** i segmenti spenti usano `outlineVariant` sul disco `strobeBackground`. In chiaro: `#D9C8BA` su `#EFE3D8`, circa 1,3:1. In scuro: `#4E3F36` su `#2E231E`, circa 1,5:1. Il criterio WCAG 1.4.11 chiede 3:1 per gli elementi grafici necessari alla comprensione.
- **Impatto:** a metronomo fermo non si vede di quanti battiti è la misura (4/4, 6/8 con i gruppi). Nel Drone non si vede la "ruota" delle 12 note. A distanza o in controluce l'anello sparisce del tutto.
- **Dove:** `metronome_screen.dart:209`, `drone_panel.dart:198`, `tuner_panel.dart:209`; `theme.dart:40-41`, `:170`, `:180`.
- **Correzione:** usare `colorScheme.outline` (`#8A7365` in chiaro, `#9C8679` in scuro) per i segmenti spenti, oppure scurire o schiarire `grainLightSoft`/`grainDarkSoft` finché arrivano a ≥3:1 sul disco. Aggiornare `test/theme_test.dart` con un controllo di contrasto tra `outlineVariant` e `strobeBackground`.

### 5. Il long-press sui tab è invisibile, ambiguo e attivo anche sull'Accordatore
- **Problema:** l'unico indizio del long-press è `onLongPressHint` per TalkBack. Il tooltip è disattivato apposta (`tooltip: ''`), quindi chi vede lo schermo non ha alcun segnale. In più, dal tab Accordatore un long-press su "Metronomo" avvia il click mentre il microfono ascolta, contraddicendo la pausa automatica del punto 1.
- **Impatto:** la funzione resta sconosciuta a quasi tutti. Chi la scopre per caso avvia o ferma il suono involontariamente, con il solo feedback aptico.
- **Dove:** `lib/app/home_shell.dart:58-82`, `:146-148`, `:159`.
- **Correzione:**
  - Dopo ogni toggle da long-press, uno `SnackBar` breve ("Metronomo avviato · 120 BPM", con azione "Annulla").
  - Fare scoprire il gesto nell'onboarding (punto 7) e mostrare un suggerimento la prima volta che si avvia il metronomo dalla sua schermata ("Suggerimento: tieni premuto il tab per avviare e fermare da qualsiasi schermata").
  - Rendere il comportamento coerente sull'Accordatore: lì il long-press va ignorato oppure applica la stessa logica di pausa.

---

## P1. Problemi importanti

### 6. Lo stato "cosa sta suonando" è debole e non arriva a TalkBack
- **Problema:** l'unico indicatore globale è un `PulsingDot` di 8 dp sull'icona del tab. Il widget `ActivityIcon` non ha semantica, quindi TalkBack legge "Metronomo, scheda 1 di 3" senza dire che sta suonando. Dal tab Drone non si vede a quanti BPM va il metronomo, anche se il piano lo segue: l'informazione c'è solo in una voce disabilitata del menu Stile (`drone_panel.dart:602-607`).
- **Dove:** `lib/widgets/pulsing_dot.dart:55-70`; `home_shell.dart:113-124`, `:139-161`.
- **Correzione:**
  - Usare il `Badge` di Material 3 (`Badge(isLabelVisible: active, smallSize: 10, child: Icon(...))`) e, quando è attivo, l'icona piena al posto di quella outlined.
  - Avvolgere la destinazione in `Semantics(value: active ? l10n.playing : null)` (nuova stringa "In riproduzione").
  - Usare l'AppBar, oggi occupata solo da "Low End", come barra di stato: per esempio `title: Text('♩ 120 · 4/4  |  La maggiore')` quando qualcosa suona, con un `IconButton(Icons.stop)` globale.

### 7. Non c'è onboarding né un aiuto, e i gesti restano nascosti
- **Problema:** non c'è nessuna schermata di primo avvio né un pulsante "?". Le interazioni principali sono implicite: toccare l'anello per avviare, toccare il centro del drone, tenere premuti − e + per salti di 5 o 10, tenere premuto il tab, fare swipe tra le sezioni, che lo slider ha "entrambi al 100% al centro", il pulsante "7".
- **Dove:** `low_end_app.dart:260-275`, `settings_page.dart:27-104`.
- **Correzione:**
  - Al primo avvio, un `showModalBottomSheet` (o una `PageView` a 3 schede) con 3 o 4 suggerimenti illustrati. Il flag `seenOnboarding` va salvato in `AppSettings`.
  - In Impostazioni, una voce `ListTile(leading: Icon(Icons.help_outline), title: Text('Gesti e scorciatoie'))` che riapre la stessa guida.

### 8. La notifica in background è generica e il tema non è selezionabile
- **Problema:** il testo della notifica è sempre "In riproduzione in background". Non dice cosa suona (metronomo? drone? a che BPM?) e si aggiorna solo quando cambia lo stato play/pausa. Inoltre `MaterialApp` non imposta `themeMode`, quindi il tema segue il sistema e non si può forzare il tema scuro solo per l'app, per esempio sul palco.
- **Dove:** `low_end_app.dart:161-173`, `:260-267`; `background_audio.dart:95-117`.
- **Correzione:**
  - Comporre il testo della notifica, per esempio "Metronomo 120 BPM · Drone La maggiore", e chiamare `show` anche quando cambiano BPM, nota o accordo, non solo lo stato.
  - Aggiungere `themeMode: _settings.themeMode` e in Impostazioni un `SegmentedButton<ThemeMode>` (Sistema / Chiaro / Scuro).

### 9. In orizzontale il quadrante e i controlli non stanno insieme sullo schermo
- **Problema:** `DialLayout` è solo verticale. Il calcolo `constraints.maxHeight - _controlsRoom` (296 dp) dà subito un valore negativo, quindi il quadrante resta al minimo di 200 dp e i controlli finiscono sotto, da scorrere. Il test `it_640x360_x1.5` verifica solo che non ci siano overflow, non l'usabilità.
- **Impatto:** con il telefono in orizzontale sul leggio si vede il quadrante oppure i BPM, non entrambi.
- **Dove:** `lib/widgets/dial.dart:113-176`.
- **Correzione:** in `LayoutBuilder`, se `constraints.maxWidth > constraints.maxHeight`, usare un `Row`: a sinistra `SizedBox.square(dimension: constraints.maxHeight - 32, child: dial)`, a destra un `Expanded(child: Column(...upper, lower, footer))`. In orizzontale conviene anche `NavigationRail` al posto di `NavigationBar` e un AppBar più basso (`toolbarHeight: 48`) o nascosto, per recuperare 56+80 dp.

### 10. I BPM non si possono inserire direttamente, e il numero non è la cosa più visibile
- **Problema:** per passare da 60 a 180 servono molti tocchi o una pressione lunga, e il passo di +5 o +10 non si scopre da soli. Il numero (displayMedium, circa 45 sp) è più piccolo del quadrante, mentre il centro dell'anello resta vuoto mentre suona (c'è solo il pallino). Inoltre `liveRegion` sul numero fa annunciare a TalkBack ogni passo durante la ripetizione.
- **Dove:** `metronome_screen.dart:140-162`, `:252-308`, `:275-276`.
- **Correzione:**
  - Rendere il numero toccabile (`InkWell` intorno alla `Column`) per aprire un dialog con `TextField(keyboardType: TextInputType.number)` e alcuni preset (60/80/100/120/140) come `ActionChip`.
  - Mostrare BPM e numero del battito grandi al centro del quadrante (`displayLarge`, 57+ sp), con il pallino dietro.
  - Spostare `liveRegion` in modo che annunci solo a fine pressione, oppure usare `SemanticsService.announce` con debounce.

### 11. Come si ferma? I suggerimenti spariscono appena si tocca
- **Problema:** il suggerimento "Tocca per iniziare" e il ▶ scompaiono appena il metronomo parte, e non compare nessuna icona ■. Nel drone il testo d'aiuto lungo ("Tocca una nota per farla suonare. Toccala di nuovo per fermarla.") sta dentro il centro con un `FittedBox(scaleDown)`, quindi con testo grande o schermi piccoli si rimpicciolisce fino a diventare illeggibile.
- **Dove:** `metronome_screen.dart:140-162`; `drone_panel.dart:122-151`, `:310-311`.
- **Correzione:** mentre suona, mostrare un'icona `Icons.stop_rounded` piccola, semi-trasparente, nel centro (o sotto i BPM). Accorciare l'aiuto del drone a "Tocca una nota" e mostrarlo fuori dal quadrante, nella riga `upper` o `lower` quando è vuota.

### 12. Il menu Stile ha un target sotto i 48 dp e icone che non corrispondono
- **Problema:** il figlio di `PopupMenuButton` è un `Padding(h:8, v:12)` con un'icona da 28, cioè circa 44×52 dp, sotto i 48 dp in larghezza. Le icone non spiegano lo stile: `music_note` = "Accordo a ogni battuta", `piano` = "Accordo a ogni beat", `show_chart` = Arpeggio. In più l'enum si chiama `held` mentre l'etichetta dice "a ogni battuta". Infine il chip "7" comunica il suo significato solo con un tooltip che si apre con la pressione lunga.
- **Dove:** `drone_panel.dart:530-548`, `:566-577`, `:609-616`.
- **Correzione:**
  - Sostituire con `MenuAnchor`, oppure con un `OutlinedButton.icon(minimumSize: Size(64,64))` che mostri anche l'etichetta breve ("Battuta" / "Beat" / "Arpeggio").
  - Scegliere icone coerenti (per esempio `Icons.crop_square` per la battuta, `Icons.more_horiz` per i beat, `Icons.trending_up` per l'arpeggio).
  - Per la settima, `FilterChip(label: Text('+7'))`, con un `Semantics(label: l10n.addSevenths)` esplicito.

### 13. Accordatore: permesso negato senza via d'uscita, verdetto piccolo
- **Problema:** il messaggio di permesso negato è un paragrafo lungo dentro la riga `upper`, senza un pulsante per aprire le impostazioni. La direzione (calante/crescente) e i cent sono in `titleMedium` (16 sp) con una freccia da 20 dp: a un metro, sul leggio, non si leggono.
- **Dove:** `tuner_panel.dart:82-95`, `:112-117`, `:394-407`.
- **Correzione:** aggiungere sotto il messaggio un `FilledButton(onPressed: openAppSettings)` (`permission_handler` o `app_settings`) con l'etichetta "Apri impostazioni". Portare il verdetto a `headlineSmall` e la freccia a `size: 32`, e colorare il testo con `_centsColor`, non solo l'icona.

---

## P2. Rifiniture

### 14. Lo slider di bilanciamento non ha etichette
Ci sono due icone e nessun valore visibile. Che al centro siano "entrambi al 100%" si legge solo nel codice. Correzione: aggiungere un segno al centro (un `SliderTheme` con `tickMarkShape` solo al centro, oppure un `Container` sottile sotto il punto medio), etichette brevi "Click" e "Drone" sotto le icone, `Slider.label` con i valori, e il doppio tap per tornare al centro. Lo slider sta anche nel PageView: uno swipe che parte poco fuori dalla traccia cambia pagina, quindi conviene darle un'altezza touch di 48 dp con `overlayShape` o padding verticale. (`lib/widgets/balance_slider.dart:24-52`)

### 15. Icone dei tab
`Icons.tune` (cursori di un mixer) non fa pensare a un accordatore, e `timer_outlined` (cronometro) fa pensare a un timer. Correzione: un'icona personalizzata a diapason, oppure `Icons.music_note` per l'Accordatore, e un'icona di metronomo (SVG o `Icons.av_timer` come ripiego). (`home_shell.dart:143`, `:163`)

### 16. Il pulsante della misura è poco chiaro, e così la lista
Il pulsante mostra solo "4/4", senza l'etichetta "Misura". Nella lista, il sottotitolo `s.feel` per le misure semplici è solo "4" e non spiega nulla. Correzione: `OutlinedButton` con una `Column` (`Text('Misura', style: labelSmall)` + `Text('4/4')`). Mostrare il sottotitolo solo per le misure composte, oppure scriverlo per esteso ("2 gruppi da 3"). (`metronome_screen.dart:386-411`, `:429-433`)

### 17. TAP
Il pulsante TAP conta il tocco su `onPointerDown`, quindi anche un tocco che inizia uno swipe del PageView viene contato. Non c'è un feedback del tipo "Tocca ancora…" e non c'è un reset visibile. Correzione: un breve flash o `HapticFeedback.selectionClick()` a ogni tocco, con un piccolo contatore sotto il testo. "TAP" e "BPM" sono testi fissi nel codice e andrebbero portati in l10n per coerenza. (`metronome_screen.dart:449-489`, `:288`)

### 18. Testi IT/EN
- "Accordo a ogni **beat**" mescola le lingue: meglio "Accordo a ogni movimento" o "a ogni quarto". (`app_localizations_it.dart:227`)
- Sull'accordatore in pausa compaiono insieme "In pausa" (riga di stato) e "Ascolta" (pulsante), quindi il messaggio è ridondante. Meglio "Accordatore in pausa: tocca Ascolta". (`:157`, `:151`)
- "Drone" resta in inglese anche in italiano. Va bene come termine tecnico, ma allora sarebbe coerente anche "Root" contro "Fondamentale".
- L'aiuto "Tocca per iniziare" può diventare "Tocca per avviare", in coerenza con "Avvia il metronomo".

### 19. La riga del drone in modalità "Fondamentale" resta vuota
`Visibility(maintainSize: true)` lascia una riga vuota da 64 dp. Si può usare quello spazio per qualcosa di utile, per esempio la scelta dell'ottava o la frequenza. (`drone_panel.dart:485-489`)

### 20. Scalatura del testo
Con testo grande, i `FittedBox` su BPM, note, centro e tab sono una buona protezione dagli overflow, ma annullano l'ingrandimento: il testo resta della stessa dimensione o si riduce. Il test con `textScale: 2` lo conferma, perché passa senza overflow. Correzione: lasciare il `FittedBox` solo dove il contenitore è geometrico (il quadrante) e far crescere le righe di controllo. Il `SingleChildScrollView` di `DialLayout` c'è già. (`accessibility_test.dart:112`)

### 21. About e logo
- La finestra About si apre solo da Impostazioni → "Informazioni su Low End". Il logo (`assets/brand/logo.png`) è largo 56 px: i dettagli della criniera e del riccio del contrabbasso si perdono, e il fondo grigio-blu neutro del logo non si abbina alla palette calda "ebony" dell'app.
- L'URL del codice sorgente è un `SelectableText`, non un link. Correzione: `TextButton(onPressed: () => launchUrl(Uri.parse(sourceCodeUrl)))` con `url_launcher`, e un logo a 72–96 dp.
- Valutare una pagina About a schermo intero (`Scaffold` con il logo grande in alto, la versione dell'app da `package_info_plus`, crediti e licenze tramite `showLicensePage`) al posto di `showAboutDialog`. (`lib/app/about.dart:10-27`)

### 22. Impostazioni
Mancano opzioni utili per il palco: tema (punto 8), schermo acceso (punto 2), suono e volume dell'accento del metronomo, feedback aptico sul battere, e "Mostra di nuovo i suggerimenti". Il `DropdownButton` del La di riferimento è duplicato tra Impostazioni e Accordatore. Va bene, ma conviene usare lo stesso widget (`ReferencePitchRow`) in entrambi per coerenza. (`settings_page.dart:76-94`, `lib/widgets/reference_pitch_row.dart`)

---

## Cosa funziona già bene
- La geometria comune del quadrante e le righe a posizione fissa (`DialLayout`): passando da un tab all'altro il quadrante resta fermo.
- Target generosi su −/+ (64 dp), TAP, misura e voicing (64 dp di altezza), e tasti delle note da almeno 48 dp (`drone_panel.dart:87`).
- Buona semantica di base: etichette "Suona La / Ferma La", `selected` sulle note, live region sull'accordatore solo quando cambia il verdetto, rispetto di `disableAnimations` (pallino e strobo fermi, con il marker statico).
- Forma oltre al colore nell'accordatore (✓ / ↑ / ↓) e grassetto sulla fondamentale nel drone.
- Test di layout su 320×568, 360×640, orizzontale, tema scuro e testo ×2, con le linee guida di accessibilità di Flutter.
