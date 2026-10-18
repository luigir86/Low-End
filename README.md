# Low End

Low End is a free, open-source practice app for musicians: a **metronome**, a piano **harmony** section and a **tuner**, in one light Android app. It was made by an amateur double bass player with the friends from the orchestra in mind, and it is useful to everyone who plays. It is built with [Flutter](https://flutter.dev), works fully offline and is available in English and Italian.

<p>
  <img src="store/graphics/phone/en-US/1_metronome.png" alt="Metronome" width="30%">
  <img src="store/graphics/phone/en-US/2_harmony.png" alt="Harmony" width="30%">
  <img src="store/graphics/phone/en-US/3_tuner.png" alt="Tuner" width="30%">
</p>

## What it does

The three tabs are **Metronome**, **Harmony** and **Tuner**, and the app opens on the metronome. Swipe left and right to change section, touch the tab you are on to start or stop its sound, or hold another tab to do it from anywhere. A pulsing dot on a tab shows that its sound is playing.

### Metronome

- Tempo from 30 to 250 BPM: touch the number to type it, hold − or + to move in steps, or tap TAP.
- Time signatures 1/1 (one click a bar), 2/4, 3/4, 4/4, 5/4, 6/8, 7/8, 9/8 and 12/8, with the beats grouped the way you count them.
- A ring that lights up beat by beat (the downbeat marked) and a short, dry woodblock-like click (higher on the downbeat), with subdivisions (eighths, triplets, sixteenths) or a swing feel (a soft skip note after beats 2 and 4), and a click on 2 and 4 only. The audio engine loops a whole bar, so the time stays steady.

### Harmony

- Twelve note keys round a dial: touch one to play it on a real piano, in time with the metronome, and touch it again to stop.
- The note alone (**Root**), a major, minor or seventh **Chord**, or a **Progression** of one chord per bar: II–V–I (major and minor), I–IV–V, I–VI–IV–V and the twelve-bar blues, in the key of the note touched. The menu names each with a well-known song (Autumn Leaves, Blue Bossa, Twist and Shout, Stand by Me, Sweet Home Chicago). The piano follows the metronome's swing and shuffle.
- Held for the bar, struck on every beat or arpeggiated; choose the octave of the root and where the chord sits (stacked, close or without the root).
- One **Balance** slider mixes the metronome and the harmony. The volume itself is the phone's.

### Tuner

- Chromatic, with a round strobe and the note in the middle: play any note and it shows up, no string to choose first.
- Under the strobe, a bar like the Balance slider shows how far off the note is: a dot on a thin track, with the shaded "in tune" zone around the middle mark.
- Finds the note with the YIN algorithm ([`lib/audio/pitch_detector.dart`](lib/audio/pitch_detector.dart)), from 28 to 2800 Hz (700 Hz with the bass chosen): from the lowest strings to the top of the violin and the flute. For B♭, E♭ and F instruments it can name the written note.
- The instrument menu switches from Chromatic to the strings of guitar, violin, viola, cello, ukulele or bass, with the string number shown.
- It listens only while it is on screen (and you can pause it). Opening the tuner pauses the metronome and the harmony, so the microphone hears only your instrument.

### Settings

The gear in the top corner opens the settings: language (English, Italian, or the phone's), note names (Do Re Mi with Italian octave numbers, La3 = 440 Hz, or C D E, A4 = 440 Hz), reference A (every hertz from 415 to 445) and an option to keep the screen on. They are kept on the phone. The gesture guide is shown at the first launch and from the settings.

With the screen off or the app in the background the metronome and the harmony keep playing, with a notification that says what is sounding.

## Free, light and accessible

- **Open source** under the [MIT License](LICENSE). Contributions are welcome: see [CONTRIBUTING.md](CONTRIBUTING.md). The components it uses and their licences are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
- **Private**: no account, no internet, no ads, no tracking; the microphone is used only while the tuner is on screen. See [PRIVACY.md](PRIVACY.md).
- **Light**: a handful of packages ([flutter_soloud](https://pub.dev/packages/flutter_soloud) for sound, [record](https://pub.dev/packages/record) for the microphone, [audio_service](https://pub.dev/packages/audio_service) for playing with the screen off, plus `shared_preferences`, `wakelock_plus`, `url_launcher` and `intl`), and the audio codecs the app doesn't need are left out of the build.
- **LLM first**: everything on screen is also an action an assistant can call, with a JSON answer, through `lowend://action/...` links. See [docs/llm.md](docs/llm.md).
- **Fast to open**: nothing heavy runs at launch. The audio engine starts only the first time a sound plays and the microphone only after the first frame is drawn (`test/startup_test.dart` checks this), and the launch screen uses the app's own background colour, so there is no white flash.
- **Accessible**: built to follow WCAG 2.1 level AA. Every control has a screen-reader label, the tuner announces the note and whether it is flat, sharp or in tune, colours keep a 3:1 contrast or better and are never the only cue, text can be enlarged, and the playing dot stops moving when the phone asks for fewer animations. `test/accessibility_test.dart` checks this automatically.

## Thanks

To the **Power Flower Orchestra of Fossano**, who inspired this app and put it to the test.

## Ideas for later

Nothing here is promised.

- Metronome: more time signatures, a tempo trainer, latency compensation.
- Harmony: more progressions and chords, just intonation.
- More languages (Spanish, German, French, Portuguese, Japanese).
- A PDF library for sheet music, set lists and annotations, and later PDF to MusicXML and MIDI playback.

## Project structure

```
lib/
  main.dart                 entry point
  actions/                  actions for assistants and automation (docs/llm.md)
  app/                      app setup, navigation, settings, theme, about and guide
  features/
    tuner/                  tuner and harmony (drone/) screens and logic
    metronome/              metronome screen and logic
  audio/                    pitch maths and sound output
  widgets/                  shared UI pieces
  l10n/                     translations (app_en.arb, app_it.arb)
test/                       automated tests (test/review: layouts, languages, text sizes)
test_screenshots/           screenshot harness used to review every screen
tool/                       scripts that make the icons, feature graphics and piano samples
assets/                     piano samples, fonts and the logo
store/                      Google Play listing: texts, graphics, checklist
docs/                       user guide, architecture, offline check, assistant actions
```

All colours, shapes and text styles live in `lib/app/theme.dart` (always dark: one bronze accent on ebony, the bronze of the icon; see [docs/tema-bronzo.md](docs/tema-bronzo.md)).

## Run it

With Flutter installed and an Android phone connected (USB debugging on):

```
flutter pub get
flutter run
```

Before opening a pull request run `dart format lib test`, `flutter analyze` and `flutter test`.

To build an APK to share with friends:

```
flutter build apk --release --split-per-abi
```

Send the `arm64-v8a` file: it fits almost every phone from the last ten years. To measure how fast the app opens, run `flutter run --profile --trace-startup`: the times are written to `build/start_up_info.json` (`timeToFirstFrameMicros` is what you feel).

### Google Play

`flutter build appbundle --release` makes the bundle for the store. It is signed with the upload key named in `android/key.properties` (git-ignored); without that file the build falls back to the debug key, which the store rejects. The listing texts, graphics and the console checklist are in [store/](store/README.md).

## Translations

Texts live in `lib/l10n/app_en.arb` (English, the reference) and `lib/l10n/app_it.arb` (Italian). After changing them, run `flutter gen-l10n`.

## Documentation

| Document | For |
| --- | --- |
| [docs/user-guide.md](docs/user-guide.md) (English), [docs/manuale-utente.md](docs/manuale-utente.md) (Italiano) | Players: what every control does |
| [docs/architecture.md](docs/architecture.md) | Developers: how the app is built |
| [docs/offline.md](docs/offline.md) | Proof that the app needs no internet, and how to check it |
| [docs/llm.md](docs/llm.md) | Assistants and automation: the `lowend://` actions |
| [PRIVACY.md](PRIVACY.md) | Privacy policy: no data collected |
| [LICENSE](LICENSE), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) | The app's licence and those of everything it uses |
| [store/README.md](store/README.md) | Google Play listing and checklist |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to help |
