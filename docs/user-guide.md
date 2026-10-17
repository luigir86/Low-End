# Low End: user guide

*Italiano: [manuale-utente.md](manuale-utente.md).*

Low End is a metronome, a piano harmony section and a tuner in one app. It was made by an amateur double bass player with the friends from the orchestra in mind, and it is meant for every musician. It is free, shows no ads, collects nothing and needs no internet.

## The three sections

The tabs at the bottom (on the left when the phone is sideways) are **Metronome**, **Harmony** and **Tuner**. The app opens on the metronome.

- **Swipe** left or right to change section. With the phone turned sideways the tabs move to a column on the left and the settings gear stays top right: **swipe up or down** over the dial or the tabs (not over the rows on the right, which may scroll) to change section. It has to be a quick flick: a slow drag does nothing. The first time you turn the phone sideways a short hint says so. For rehearsals, **Lock the gestures** in the settings turns off the swipes and the hold on a tab, so that only taps are left.
- **Touch the tab you are on** to start or stop its sound, like the middle of its dial. **Hold another tab** to start or stop that section's sound from anywhere (the metronome, or the harmony).
- A **pulsing dot** on a tab says that section is making sound: the metronome and the harmony while they play, the tuner while it listens.
- The first time you open the app a short **gesture guide** appears. It is also in *Settings → Gestures and shortcuts*.

The volume is the phone's: use its volume keys. The slider at the bottom of the Metronome and Harmony sections only balances one against the other: touch an icon to go all the way to that side, the middle to have both at full level.

## Metronome

- **Start and stop**: touch the ring or the number in the middle. The ring lights up beat by beat, with the first beat marked, and a short, dry click keeps the time, a little higher on the first beat.
- **Tempo**: from 30 to 250 BPM, with its Italian name (Largo, Andante, Allegro…) under the number while it plays. Touch the pencil to type it; touch **+** or **−** to move by one, or hold them to move in steps of 5 and 10; or tap **TAP** (the coloured button) in the rhythm you want.
- **Straight / Swing**: how the beat is played. Swing adds a soft skip note after beats 2 and 4 (long, short), like a jazz ride. The piano of the Harmony tab follows: in the *every beat* and *arpeggio* styles it plays the skip notes too, in time with the click. In the bars counted in eighths (6/8, 7/8, 9/8, 12/8) it is always straight.
- The tempo, the time signature and the feel are kept when you close the app.
- **Time signature**: the box with "4/4" in it (no title: touch it to choose). 1/1 (one click per bar, to keep a tempo without counting), 2/4, 3/4, 4/4, 5/4, 6/8, 7/8, 9/8 and 12/8. In 6/8, 9/8 and 12/8 the tempo counts dotted quarter notes (♩.), the way you conduct them; in 7/8 it counts eighths.
- Changing the tempo or the time signature while it plays takes effect at once, without a gap.

## Harmony

Twelve keys round a dial (by default in the circle of fifths; you can ask for semitones in Settings).

- **Touch a key** to play it on a real piano, in time with the metronome. **Touch it again** to stop. The harmony and the metronome can play together or alone.
- **Hold C♯ or F♯** to write them D♭ or G♭.
- **Root**: the note alone. **Chord**: major, minor or seventh, built on the note. **Progression**: one chord per bar, in the key of the note you touched: II–V–I (major and minor), I–IV–V, I–VI–IV–V and the twelve-bar blues. The menu says what each is: *Jazz standard, like Autumn Leaves* (II–V–I), *Jazz in a minor key, like Blue Bossa*, *Rock ’n’ roll, like Twist and Shout* (I–IV–V), *’50s–’60s pop, like Stand by Me* (I–VI–IV–V) and *Blues, like Sweet Home Chicago*. The dial fades the notes outside the key and writes the Roman numerals (II, V, I) small on the notes they stand on, and they stay put: read II, then go to V. "Add the seventh" turns the chords into sevenths.
- **Style**: the chord struck once a bar, on every beat, or played as an arpeggio, at the metronome's tempo and time signature.
- **Sound options**: the octave of the root, and where the chord sits (stacked, close, or without the root so you can play it yourself).
- **Balance**: one slider mixes metronome and harmony.

## Tuner

- The tuner listens by itself when you open the section (the first time Android asks for the **microphone**). Play a note: its name appears in the middle of the round strobe. The rings of the strobe turn anticlockwise when the note is **flat** and clockwise when it is **sharp**, faster the further off you are, and stand still when you are **in tune** (within 5 cents by default; the settings offer 2 or 10), under the dial a straight scale shows the same thing by position, and a note that is only being held after the string stopped fades. The words *Flat*, *In tune* and *Sharp* and the number of cents are written too, and a screen reader reads them out.
- The reference A is under the dial: **−** and **+** move by 1 Hz, and the pencil takes a typed value or one of the standard ones (415, 432, 440, 442 Hz).
- It hears notes from 28 Hz to 700 Hz, and it names any note, with no string to choose first.
- The **Instrument** menu switches from Chromatic to the strings of guitar, violin, viola, cello, ukulele or bass, and shows the number of the string.
- **Listen / Pause**: touch the middle of the dial to pause it whenever you want; it stays paused until you touch it again.
- The tuner **pauses the metronome and the harmony** while you are on it, so the microphone hears only your instrument; they carry on when you leave.
- The sound is analysed on the phone and never recorded or sent anywhere.
- If you said no to the microphone, allow it in the phone settings under *Apps › Low End › Permissions*; the app shows a button that opens that page.

## Settings

The gear at the top opens the settings:

| Setting | Choices |
| --- | --- |
| Language | Same as the phone, English, Italian |
| Note names | Follow the language, Do Re Mi (La3 = 440 Hz), C D E (A4 = 440 Hz) |
| Reference A | every hertz from 415 to 445, for the tuner and the harmony |
| Harmony circle | Circle of fifths, or in semitones |
| Theme | Follow the phone, light, dark |
| Keep the screen on | While something plays or the tuner listens |
| Gestures and shortcuts | Shows the guide again |

**About Low End** (at the bottom of the settings) shows the licence, the source-code link and, under *View licences*, the licences of everything the app is built with, fonts and piano sounds included. Below the choices, **Thanks** is for the Power Flower Orchestra of Fossano, who inspired this app and put it to the test.

## Playing with the screen off

The metronome and the harmony keep playing when you lock the phone or switch to another app. A notification says what is playing, with buttons to pause or resume, and to stop. Android may ask permission to show notifications the first time.

## Questions and problems

Write to ribaluigi@gmail.com or open an issue at https://github.com/luigir86/Low-End/issues.
