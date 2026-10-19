# Style sheet

One place that says what Low End looks like, so that a new screen is built from the same few pieces. The sizes live in `lib/app/style.dart`, the colours in `lib/app/theme.dart` (`Palette`), the geometry of the dials in `lib/widgets/dial.dart`. `test/style_test.dart` fails if a font size is written anywhere else, or if any text in the theme is below the minimum.

## Harmony between the sections

The metronome, the harmony and the tuner do different things, but they must look like one app: **share shapes and proportions as much as possible, and when in doubt make a section look like the others, not like itself.** In practice:

- The dial is the same size, in the same place, on all three tabs; its middle is the button and says the state in the same two sizes (display, then caption).
- Under it, the same three rows. The first is empty on the metronome and the harmony, so that their controls sit lower, near the thumb, and holds the cents bar on the tuner, next to the strobe. The second is a pill or a switch: on the metronome a pill with two halves that open menus (the time signature, and what fills the beat: note figures drawn by `NoteIcon`: a quarter, two eighths beamed, a beamed triplet under a 3, four sixteenths beamed, and the swung ones with the word "Swing" beside them); on the harmony Root / Chord / Progression; on the tuner Chromatic | instrument. The third is the row of controls: TAP over half the row with −, + and the pencil on the metronome; the chord or progression menu and the options on the harmony; the reference A on the tuner.
- The row of controls is built from the same pieces everywhere (`lib/widgets/row_controls.dart`): a **field with its name on the border** (the reference A; on the harmony with the note alone, the Example songs field, a bare border that keeps its name for screen readers: `LabeledField(showLabel: false)`), **chips** (TAP, −, +) and an **icon button** at the end (the sound options, the pencil). A new control is made from these; if none fits, change them for everyone.
- **A chip that is a button to press is filled.** The chips that show a value or step it (−, +) are outlined; TAP, which you play rather than set, is filled with `primaryContainer` and its text is `onPrimaryContainer` (`RowChip(filled: true)`), so that it reads as pressable. The pair keeps the contrast checked by `theme_test.dart` and `accessibility_test.dart`.
- − and + step a value, the pencil types it or chooses from a list, a touch on the field opens the same choice. Where holding − or + runs the value (the metronome's tempo), the chips have no tooltip, which a hold would open: their name is a semantics label.

## Type

Font: Edwin (Noto Music for ♩ ♫ ♬). Sizes in sp, they grow with the phone's text size and shrink to fit where needed (`FittedBox`, never overflow).

| Role | sp | Text style | Used for |
| --- | --- | --- | --- |
| display | 45 | `displayMedium`, weight 600 | The value in the middle of a dial: the tempo, the note on the tuner, the note on the harmony. The octave beside a note is 0.4 of it. |
| headline | 24 | `headlineSmall` | The verdict on the tuner ("Flat −20 cents"). |
| title | 22 | `titleLarge`, weight 700 | A value on a control: the time signature, TAP. |
| body | 16 | `titleMedium`, `bodyLarge` | The chord on the harmony dial, the notes on the keys, the chord menu, dialog titles. |
| caption | 14 | `bodyMedium`, `titleSmall`, `labelLarge` | Hints in the middle of a dial ("Tap to start", "Touch a note to play", "Play a note", "Listen"), the unit under the tempo, messages, settings. |
| small | 13 | `labelMedium`, `labelSmall`, `bodySmall`, tab labels | The smallest text anywhere: the names of the tabs, the note under a progression's name in the menu ("Jazz standard, like Autumn Leaves"), the second name of a note (D♭). Nothing is smaller. |

Rules: pick a role, never a number; the three dials show their value in `display`, and their hint in `caption`; text smaller than `small` is not allowed, so if something does not fit, shorten it or let it shrink with the user's text size, do not make it tiny.

## Shapes

| What | Value |
| --- | --- |
| Corner radius of buttons, cards, menus | 16 (`LowEndShape.radius`) |
| Round or rounded control | at least 48 × 48, the smallest touch target |
| Rows under a dial | three rows of the same height (`DialLayout.rowHeight`, 80, spacing included) and no space between them, on every tab: a dial and three rows. Second row: the pill of the metronome (time signature \| what fills the beat) and of the tuner (Chromatic \| instrument), 40 dp high to the eye and 48 to touch (`PillSwitch`), and the harmony's Root / Chord / Progression (64 high, `LowEndShape.row`). Third row: the row of controls. First row: empty on the metronome and the harmony (the same height, so that their rows sit where the tuner's do); on the tuner a cents bar (thin track, 2 by 16 middle mark, round thumb, no shaded zone, with the word "Cents" over it and −50, 0, +50 written under it; the thumb takes the verdict's colour and shrinks from 10 to 5 dp the further off the note is, grey while a note is only held). The row of controls is the field, chips and icon button of `row_controls.dart`, all as tall as a line of text with the same padding (so they grow together with large text): TAP, −, +, pencil on the metronome; chord / progression, options on the harmony (the Example songs field instead of the chord menu with the note alone); reference A, −, +, pencil on the tuner |
| Dial and rows | the dial at the same height on every tab; the controls sit lower, nearer the thumb, with only a little room left under them for a row that grows (`DialLayout`) |
| Dial | one disc, a ring from 0.64 to 0.97 of the radius, a hub of 0.61; the same position and size on every tab (`DialGeometry`, `dial_alignment_test.dart`) |
| Ring segments | metronome: thinner band (0.22 to 0.92 of the ring), one segment per beat, the lit "one" wider (0.12 to 1), a bar of one beat is a whole ring; harmony: the whole ring, twelve keys; tuner: two bands of thin segments |

## Colour

Bronze on ebony (full notes in [tema-bronzo.md](tema-bronzo.md)): always dark, no choice of theme, and one accent for the whole app, the honey bronze of the lion on the icon. Everything else is neutral and everything is flat: no gradients, no sheen. Every other shade is the bronze mixed into the ebony (`LowEndTheme.tint`), so the three tabs look like one app and are told apart by their icons, names and dials.

| Meaning | Colour |
| --- | --- |
| Surface, text, muted text | ebony `ebony`, `inkOnDark`, `inkOnDarkMuted` with a quarter of bronze |
| Accent (lit beats, the note sounding on the harmony, the borders) | bronze `#D4A373` |
| Shades of the accent | the bronze mixed into the ebony: disc 10 %, keys and beats that are off 26 %, the chosen pill and TAP 20 %, the rest of a chord 55 %, the tuner's segments 60 % (so the strobe does not outweigh the note), borders and the other lit beats 75 % |
| The metronome's "one" | the accent at full strength, and wider than the other beats (it fills the ring's margins), so it is told by its shape too |
| Choices of a switch | the chosen one filled, in ink; the others in the muted ink, never in the accent |
| Icons on the row of controls | the ink of the text; the bronze is on the borders |
| Tuner verdict | in tune green, close yellow, off pure red (`inTune`, `close`, `off`), on the verdict words and their tick or arrow, and on the thumb of the cents bar (the note itself is in ink, like the middle of every dial), always with a shape (a tick or an arrow) as well. They are never the bronze: the yellow is at least 20 degrees of hue away from it |
| The functions of a progression (harmony) | its Roman numerals (I, II, V) written small on the notes they stand on, and still while it plays; nothing moves to say what is next |

All text and shapes keep at least 4.5:1 / 3:1 contrast (`theme_test.dart`, `accessibility_test.dart`).

## Landscape

When the screen is wider than tall (`DialLayout.isLandscape`) the same pieces are laid out in a row: **tab rail | dial | column of the three rows**. The portrait layout does not change.

- **Rail**: on the left, inside the safe areas, an icon above its name (`labelMedium`, 13 sp, 96 dp wide), the same three tabs as the bottom bar; a tab only goes to its section.
- **Dial**: nearly the whole height (height − 56, at most 420), next to the rail, so it is not centred on the screen. It gets smaller (down to 160) on narrow phones to leave the column its minimum width, `DialLayout.columnMinWidth` (320).
- **Column**: the three rows of `DialLayout.rowHeight` (80), no space between them, at the same place on every tab (the tuner has all three: the cents bar, the switch, the reference A); it scrolls with large text. The **settings gear** is above it, top right.
- **Swipe**: up or down on the dial or the rail changes section (up: the next one), like a vertical page view; not on the column of rows, and not from the top or bottom 32 dp of the screen (notification shade, home gesture). It must go 72 dp within half a second, so that a resting finger or a slow drag does not change section; with the gestures locked in the settings it does nothing. In portrait the swipe stays horizontal. See `FlipDetector`.
- `dial_alignment_test.dart` and `test/review/` check this at 915 × 412, 640 × 360, 1280 × 800 and with large text.

## Dials

The middle of a dial is its button: touching it starts or stops the metronome, the harmony, or the tuner's listening. It is the only way to start or stop a sound by touch: the tabs and the swipes only navigate. What is written there is the state: the value (display), then one hint (caption) when stopped. On the tuner, while the metronome or the harmony plays, the hint adds that listening pauses them; touching the dial pauses them and a snackbar offers *Resume*.

When one starts while the other plays, it comes in on the other's next bar line: until then the middle of its dial shows the seconds to go, large and in the muted ink (the metronome in place of the tempo, the harmony in place of the note, with the chord under it).

## Motion

No timings of our own: movement uses what Flutter and Material 3 provide, so the app moves like the rest of Android and follows it when it changes.

| What | Duration and curve |
| --- | --- |
| Settings page | the system page transition (`MaterialPageRoute` and the theme's `pageTransitionsTheme`), left as it is |
| Sheets, dialogs, snackbars | the Material defaults, left as they are |
| Slide to another section, tab bar indicator | `Durations.medium1` (250 ms), `Easing.standard` |
| A state that changes in place: the filled half of a pill, the rail's indicator, a control greyed out (`enabled`), the note that fades when only held | `Durations.short4` (200 ms), `Easing.standard` |

Rules: write `Durations.*` and `Easing.*`, never a `Duration(milliseconds: …)` or a `Curves.*` for something the player sees. Every animation of a change takes zero time when `MediaQuery.disableAnimationsOf(context)` is true (the phone is set to fewer animations). What moves with the music (the beat ring, the strobe) is not a transition and follows the sound, not these values.
