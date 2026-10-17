# Style sheet

One place that says what Low End looks like, so that a new screen is built from the same few pieces. The sizes live in `lib/app/style.dart`, the colours in `lib/app/theme.dart` (`Palette`), the geometry of the dials in `lib/widgets/dial.dart`. `test/style_test.dart` fails if a font size is written anywhere else, or if any text in the theme is below the minimum.

## Harmony between the sections

The metronome, the harmony and the tuner do different things, but they must look like one app: **share shapes and proportions as much as possible, and when in doubt make a section look like the others, not like itself.** In practice:

- The dial is the same size, in the same place, on all three tabs; its middle is the button and says the state in the same two sizes (display, then caption).
- Under it, the same three rows: a switch (Root / Chord / Progression, Straight / Swing) or a message, then the row of controls, then the balance slider.
- The row of controls is built from the same pieces everywhere (`lib/widgets/row_controls.dart`): a **field with its name on the border** (the chord or progression, the reference A; the time signature is a bare border with "4/4" in it, since its title did not fit, but it keeps its name for screen readers: `LabeledField(showLabel: false)`), **chips** (+7, TAP, −, +) and an **icon button** at the end (the sound options, the pencil). A new control is made from these; if none fits, change them for everyone.
- **A chip that is a button to press is filled.** The chips that show a value or step it (+7, −, +) are outlined; TAP, which you play rather than set, is filled with `primaryContainer` and its text is `onPrimaryContainer` (`RowChip(filled: true)`), so that it reads as pressable. The pair keeps the contrast checked by `theme_test.dart` and `accessibility_test.dart`.
- − and + step a value, the pencil types it or chooses from a list, a touch on the field opens the same choice.

## Type

Font: Edwin (Noto Music for ♩). Sizes in sp, they grow with the phone's text size and shrink to fit where needed (`FittedBox`, never overflow).

| Role | sp | Text style | Used for |
| --- | --- | --- | --- |
| display | 45 | `displayMedium`, weight 600 | The value in the middle of a dial: the tempo, the note on the tuner, the note on the harmony. The octave beside a note is 0.4 of it. |
| headline | 24 | `headlineSmall` | The verdict on the tuner ("Flat −20 cents"). |
| title | 22 | `titleLarge`, weight 700 | A value on a control: the time signature, TAP. |
| body | 16 | `titleMedium`, `bodyLarge` | The chord on the harmony dial, the notes on the keys, the chord menu, dialog titles. |
| caption | 14 | `bodyMedium`, `titleSmall`, `labelLarge` | Hints in the middle of a dial ("Tap to start", "Touch a note to play", "Play a note", "Listen"), the unit under the tempo, messages, settings. |
| small | 13 | `labelMedium`, `labelSmall`, `bodySmall`, tab labels | The smallest text anywhere: the names under the icons of the balance slider and of the tabs, the note under a progression's name in the menu ("Jazz standard, like Autumn Leaves"), the second name of a note (D♭). Nothing is smaller. |

Rules: pick a role, never a number; the three dials show their value in `display`, and their hint in `caption`; text smaller than `small` is not allowed, so if something does not fit, shorten it or let it shrink with the user's text size, do not make it tiny.

## Shapes

| What | Value |
| --- | --- |
| Corner radius of buttons, cards, menus | 16 (`LowEndShape.radius`) |
| Round or rounded control | 48 × 48 at least (`LowEndShape.control`), the smallest touch target |
| Rows under a dial | three rows of the same height (`DialLayout.rowHeight`, 80, spacing included) and no space between them, on every tab: a dial and three rows. Metronome and harmony: the switch (64 high, `LowEndShape.row`), then the row of controls, then the balance slider; the tuner only fills the second (the reference A), keeping the first and the third empty. The row of controls is the field (56), chips (48) and icon button (52, `LowEndShape.iconButton`) of `row_controls.dart`: chord / progression, +7, options on the harmony; time signature, TAP, −, +, pencil on the metronome; reference A, −, +, pencil on the tuner |
| + over − pair | two 48 × 48 buttons, rounded outside and almost square where they meet |
| Dial | one disc, a ring from 0.64 to 0.97 of the radius, a hub of 0.61; the same position and size on every tab (`DialGeometry`, `dial_alignment_test.dart`) |
| Ring segments | metronome: thinner band (0.22 to 0.92 of the ring), one segment per beat, a bar of one beat is a whole ring; harmony: the whole ring, twelve keys; tuner: two bands of thin segments |

## Colour

Wood. Light: maple surfaces, walnut text and primary. Dark: ebony surfaces, a light mocha primary. Signature colour: Mocha Mousse (PANTONE 17-1230).

| Meaning | Colour (light / dark) |
| --- | --- |
| Surface, text, muted text, lines | `maple` / `ebony`, `inkOnLight` / `inkOnDark`, `inkOnLightMuted` / `inkOnDarkMuted`, `grainLight` / `grainDark` |
| Primary (what is playing, lit beats) | `walnut` / `mochaLight` |
| Secondary (the rest of a chord) | `mochaMousse` |
| The metronome's "one" | `downbeatLight` (burnt orange) / `downbeatDark` (cream): unlike the other beats, it must be seen on a dark stage |
| Tuner verdict | in tune green, close ochre, off red (`inTune*`, `close*`, `off*`), always with a shape (a tick or an arrow) as well |
| The functions of a progression (harmony) | its Roman numerals (I, II, V) written small on the notes they stand on, and still while it plays; nothing moves to say what is next |

All text and shapes keep at least 4.5:1 / 3:1 contrast (`theme_test.dart`, `accessibility_test.dart`).

## Dials

The middle of a dial is its button: touching it starts or stops the metronome, the harmony, the tuner. What is written there is the state: the value (display), then one hint (caption) when stopped.
