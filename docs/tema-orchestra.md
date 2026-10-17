# Tema Orchestra per Low End

Stato: **proposta validata da Luigi sugli screenshot, non ancora nel codice di `main`**. Il prototipo è nella cartella di prova `.claude/worktrees/orchestra-preview` (ramo `orchestra-preview`, non salvato su GitHub). Le immagini sono in `dist/orchestra/finale/`, generate con `flutter test test_screenshots/ui_review_test.dart --update-goldens --name "^(it_light|it_dark) "`.

## 1. L'idea in una frase

Ogni scheda ha il colore di un materiale dell'orchestra, e solo quello: **ottone** per il Metronomo, **palissandro** (il legno degli archi) per l'Armonia, **argento** per l'Accordatore. Tutto il resto è neutro, tutto è piatto.

## 2. Perché questa scelta

- **Coerenza con la musica.** Ottone, legno e argento sono materiali di strumenti veri, non colori "da app". Il metronomo è di ottone (il pendolo), l'armonia è nel legno di violini e chitarre, l'accordatore è d'argento (il diapason).
- **Tre schede riconoscibili a colpo d'occhio.** Giallo bruno, rosso-marrone scuro e grigio acciaio cambiano insieme tonalità e luminosità; un'alternativa a tre blu/rossi/viola era troppo fredda, una a tre caldi (ambra, terracotta, mora) troppo simile tra schede.
- **Sfondo neutro, non legno.** Il fondo è un ebano grigio in scuro e un grigio neutro in chiaro, così i tre colori risaltano e il tema non somiglia a un'app di falegnameria.
- **I verdetti dell'accordatore restano verde, ocra e rosso** e si leggono solo sulla **nota**: il cerchio e il cursore sono sempre argento. Verde e rosso non sono mai usati come colore di una scheda, quindi non si confondono con il significato "intonato" o "lontano".
- **Piatto.** Provato un riflesso metallico su ottone e argento: più "bello" ma meno sobrio; Luigi preferisce piatto.

## 3. Palette

| Scheda | Colore (chiaro) | Colore (scuro) |
|---|---|---|
| Metronomo, ottone | #8A6508 | #E3B84A |
| Armonia, palissandro | #8A4A33 | #D88F6E |
| Accordatore, argento | #5E6B7A | #B4C0CF |

Sfondi e inchiostri: chiaro = sfondo #F1F0EE, centro del cerchio #FAF9F8, testo #1E1C1A; scuro = sfondo #141312, superfici #1C1B19, testo #EFEDEA.

Ogni altra tinta di una scheda è il suo colore **mescolato nello sfondo**: disco al 10%, segmenti spenti al 26%, contenitore della scheda attiva al 20%, note dell'accordo al 55%, bordi al 75%. Il primo battito del metronomo è una variante più scura (chiaro) o quasi crema (scuro) dello stesso colore.

Cosa è tinto da una scheda: cerchio (disco, anello, segmenti), bordi e pulsanti, interruttori, cursore, pillola e pallino della scheda in basso, seconda voce dell'accordo. **Non** è tinto: sfondo, barra dei tab, verdetti dell'accordatore.

## 4. Contrasto (misurato, WCAG, rapporto di luminanza)

| Scheda | Accento su sfondo chiaro | Accento su sfondo scuro | Bordi (tinta 75%) chiaro / scuro |
|---|---|---|---|
| Metronomo | 4,7 : 1 | 9,9 : 1 | 3,0 / 6,0 : 1 |
| Armonia | 5,9 : 1 | 7,1 : 1 | 3,5 / 4,5 : 1 |
| Accordatore | 4,8 : 1 | 10,1 : 1 | 3,0 / 6,1 : 1 |

- Testo sulle note dell'accordo (tinta 55%): 6,2–7,0 : 1 in chiaro; in scuro 5,3 : 1 per l'Armonia (le note d'accordo esistono solo lì); per ottone e argento in scuro 4,2 : 1 ma non compaiono su quelle schede.
- Note dell'accordatore sul centro del cerchio: verde 6,1 / 9,7, ocra 5,6 / 10,7, rosso 6,4 / 10,1 : 1 (chiaro / scuro).
- I **segmenti spenti** sono solo decorazione (1,4–1,8 : 1 sullo sfondo): hanno un bordo a 3 : 1 e il significato non dipende dal colore.

## 5. Accessibilità del verdetto dell'accordatore

La nota cambia colore, ma il verdetto è detto anche da parole ("Intonato", "Calante −9 cent"), dalla freccia o dalla spunta, e dal verso in cui girano i segmenti: nessuna informazione è affidata al solo colore.

## 6. Schermate (italiano)

`dist/orchestra/finale/`: 1 metronomo chiaro, 2 metronomo scuro, 3 armonia chiaro, 4 armonia scuro, 5 accordatore intonato (verde, chiaro), 6 accordatore quasi intonato (ocra, scuro), 7 accordatore lontano (rosso, chiaro).

## 7. Limiti noti

- L'argento è poco saturo: sul cerchio dell'accordatore conta di più il verdetto che il colore della scheda.
- Ottone (giallo bruno) e palissandro (rosso-marrone) restano i due colori più vicini; si distinguono per tonalità e luminosità.
- I contrasti sono misurati sui colori calcolati con `Color.lerp` nel codice; i test di contrasto dell'app non sono ancora stati aggiornati ai nuovi colori.
- Prototipo basato sul lavoro non salvato della sessione `taste-polish` (colori per scheda): va integrato lì o riscritto da `main`.

## 8. Cosa chiedere a una valutazione estetica

Coerenza del sistema, gerarchia visiva (cerchio, nota, controlli), carattere e personalità rispetto ad altre app musicali, equilibrio tra sobrietà e calore, se le tre schede sembrano la stessa app, punti deboli concreti con rimedi piccoli.
