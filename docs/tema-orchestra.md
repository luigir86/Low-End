# Tema Orchestra per Low End

Stato: **nel codice di `main`**. Le schermate del negozio sono in `store/graphics/phone/<lingua>/` (`flutter test test_screenshots/store_screenshots_test.dart --update-goldens`); quelle di revisione, in chiaro e in scuro, si generano con `flutter test test_screenshots/ui_review_test.dart --update-goldens --name "^(it_light|it_dark) "` in `test_screenshots/goldens/`.

## 1. L'idea in una frase

Ogni scheda ha il colore di un materiale dell'orchestra, e solo quello: **ottone** per il Metronomo, **palissandro** (il legno degli archi) per l'Armonia, **argento** per l'Accordatore. Tutto il resto è neutro, tutto è piatto.

## 2. Perché questa scelta

- **Coerenza con la musica.** Ottone, legno e argento sono materiali di strumenti veri, non colori "da app". Il metronomo è di ottone (il pendolo), l'armonia è nel legno di violini e chitarre, l'accordatore è d'argento (il diapason).
- **Tre schede riconoscibili a colpo d'occhio.** Giallo bruno, rosso-marrone e grigio acciaio cambiano insieme tonalità e luminosità.
- **Sfondo neutro, non legno.** Il fondo è un ebano grigio in scuro e un grigio neutro in chiaro, così i tre colori risaltano.
- **I verdetti dell'accordatore sono verde, arancio e rosso** e si leggono solo sulla **scritta del verdetto** (con la sua freccia o spunta): la nota è nera o bianca come al centro degli altri cerchi, e il cerchio e il cursore sono sempre argento. Nessun verdetto ha il colore di una scheda: l'arancio non è l'ottone, il rosso è un rosso puro e non il palissandro.
- **Piatto.** Provato un riflesso metallico su ottone e argento: più "bello" ma meno sobrio; Luigi preferisce piatto.

## 3. Palette

| Scheda | Colore (chiaro) | Colore (scuro) |
|---|---|---|
| Metronomo, ottone | #8A6508 | #E3B84A |
| Armonia, palissandro | #8A4A33 | #D88F6E |
| Accordatore, argento | #5E6B7A | #B4C0CF |

Sfondi e inchiostri: chiaro = sfondo #F1F0EE, testo #1E1C1A; scuro = sfondo #141312, superfici #1C1B19, testo #EFEDEA. La schermata di avvio di Android usa gli stessi sfondi (`android/app/src/main/res/values*/colors.xml`).

Verdetti dell'accordatore: intonato #2E6B3A / #8FD19E, quasi #A64B00 / #FFA05A (arancio), lontano #C62828 / #FF8A80 (chiaro / scuro).

Ogni altra tinta di una scheda è il suo colore **mescolato nello sfondo**: disco 10%, segmenti spenti 26%, pillola scelta e TAP 20%, note dell'accordo 55%, bordi, battiti accesi e segmenti dell'accordatore 90% in chiaro e 75% in scuro.

Cosa è tinto da una scheda: cerchio (disco, anello, segmenti), bordi, cursore, pillola e pallino della scheda in basso, seconda voce dell'accordo. **Non** è tinto: sfondo, barra dei tab, testo, la nota al centro dell'Armonia e dell'Accordatore, icone dei pulsanti, scelte non selezionate degli interruttori, verdetti dell'accordatore.

## 4. Regole emerse dalla revisione estetica (skill "taste")

1. **Il primo battito è l'ottone pieno**, e più largo degli altri (riempie i margini dell'anello): si riconosce anche dalla forma. Gli altri battiti accesi sono lo stesso colore un passo più tenue.
2. **I verdetti non somigliano alle schede** (vedi palette).
3. **Negli interruttori** (Dritto / Swing, Tonica / Accordo / Progressione) la scelta fatta è piena e in inchiostro; le altre sono nell'inchiostro attenuato, mai nel colore della scheda.
4. **Il cerchio dell'accordatore** ha i segmenti un passo più tenui dell'argento pieno, così non pesa più degli altri cerchi e la nota resta la cosa più forte.
5. **Le righe dei controlli stanno più in basso**, vicino al pollice, senza la fascia vuota sopra la barra dei tab; il cerchio resta nello stesso punto su tutte le schede.
6. **Le icone dei pulsanti** (matita, opzioni) sono nell'inchiostro del testo come − e +; il colore della scheda resta sui bordi.

## 5. Contrasto (WCAG)

`test/theme_test.dart` controlla, per ogni scheda in chiaro e in scuro: colore della scheda sullo sfondo almeno 4,5 : 1; bordi e battiti accesi sullo sfondo e sul disco almeno 3 : 1; testo sulla pillola scelta almeno 4,5 : 1; testo sulle note dell'accordo almeno 4,5 : 1 sull'Armonia (dove esistono) e 4 : 1 altrove; verdetti sul disco e sullo sfondo almeno 3 : 1. I **segmenti spenti** sono solo decorazione: hanno un bordo a 3 : 1 e il significato non dipende dal colore.

## 6. Accessibilità del verdetto dell'accordatore

La scritta del verdetto cambia colore, ma il verdetto è detto anche da parole ("Intonato", "Calante −9 cent"), dalla freccia o dalla spunta, e dal verso in cui girano i segmenti: nessuna informazione è affidata al solo colore.

## 7. Icona

L'icona (il leone sul riccio del contrabbasso, in legno e bronzo su fondo scuro) **resta com'è**. È già fatta degli stessi materiali del tema (legno e ottone) e funziona piccola sullo schermo del telefono; un'icona con chiaroscuro è normale anche quando l'app è piatta. Il fondo dell'icona e della grafica del negozio è un marrone molto scuro (#1B1411), appena più caldo del nuovo ebano (#141312): la differenza non si vede sul telefono. Ridisegnarla piatta sarebbe una scelta di marchio, da fare solo se Luigi lo vuole.

## 8. Limiti noti

- L'argento è poco saturo: sul cerchio dell'accordatore conta di più il verdetto che il colore della scheda.
- Ottone (giallo bruno) e palissandro (rosso-marrone) restano i due colori più vicini; si distinguono per tonalità e luminosità.
