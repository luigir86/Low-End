# Low End

Low End is a mobile app for double bass and electric bass players, built with [Flutter](https://flutter.dev) for Android and iOS.

## Planned features

1. **Tuner** for double bass and electric bass, chromatic with a round strobe in the style of Peterson tuners and the note in the middle: play any note and it shows up, no tuning to choose.
2. **Drone**: its own tab, with twelve note keys round a dial. Touch a key to play that note in the middle octave, touch it again to stop; play the note alone or a major, minor or seventh chord in pure intervals. Loudness follows the phone volume. Also reachable from the Metronome.
3. **Metronome**: its own tab, in 4/4 for now, with a ring of four segments that light up clockwise (the "one" at the top in brass) and a dot in the middle that swells on every beat. Touch the ring to start and stop; − and + (hold to go faster) and TAP set the tempo, from 30 to 250 BPM, starting at 80. The click is a short woodblock tick, a little higher on the first beat; the audio engine loops a whole bar, so the time stays steady.
4. **PDF library** for sheet music, set lists and annotations (later: the app starts with the tuner, drone and metronome).
5. **PDF to MusicXML** conversion (beta, server-side optical music recognition).
6. **MIDI playback** of converted scores, at the real sounding octave.

The app is available in English and Italian.

The tuner starts listening as soon as it is on screen (you can pause it, and it stays paused until you tap Listen), and stops as soon as you leave it or the app goes to the background. It finds the note with the YIN algorithm (`lib/audio/pitch_detector.dart`), down to the low B of five-string basses. It listens from 28 to 700 Hz, the range of the bass, and keeps following a note as it rings out.

The gear at the top opens the **settings**: app language (English or Italian, or the phone's), note names (Do Re Mi with Italian octave numbers, La3 = 440 Hz, or C D E, A4 = 440 Hz) and the reference A, from 438 to 445 Hz. They are kept on the phone.

Each section starts and stops its own sound, and the drone and the metronome can play together. A pulsing dot on a tab shows that its sound is playing. Opening the tuner pauses them (so the microphone hears only the bass) and leaving it they carry on; with the screen off or the app in the background they stop.

## Free, light and accessible

- **Open source** under the [MIT License](LICENSE). Contributions are welcome: see [CONTRIBUTING.md](CONTRIBUTING.md).
- **Private**: no account, no internet, no tracking; the microphone is used only while the tuner is on screen. See [PRIVACY.md](PRIVACY.md).
- **Light**: only two audio packages ([flutter_soloud](https://pub.dev/packages/flutter_soloud) for sound, [record](https://pub.dev/packages/record) for the microphone) and [shared_preferences](https://pub.dev/packages/shared_preferences) for the settings, one permission (microphone), and the audio codecs the app doesn't need are left out of the build.
- **LLM first**: everything on screen is also an action an assistant can call, with a JSON answer, through `lowend://action/...` links. See [docs/llm.md](docs/llm.md).
- **Fast to open**: nothing heavy runs at launch. The audio engine starts only the first time a sound plays and the microphone only after the first frame is drawn (`test/startup_test.dart` checks this), and the launch screen uses the app's own background colour, so there is no white flash.
- **Accessible**: built to follow WCAG 2.1 level AA. Every control has a screen-reader label, the tuner announces the note and whether it is flat, sharp or in tune, colours keep a 3:1 contrast or better and are never the only cue, text can be enlarged, and the playing dot stops moving when the phone asks for fewer animations. `test/accessibility_test.dart` checks this automatically.

## Project structure

```
lib/
  main.dart                 entry point
  actions/                  actions for assistants and automation (docs/llm.md)
  app/                      app setup and main navigation
  features/
    tuner/                  tuner and drone screens and logic
    metronome/              metronome screen and logic
  audio/                    pitch maths and sound output
  widgets/                  shared UI pieces
  app/theme.dart            colours, shapes and text styles (wood palette, Pantone Mocha Mousse)
  l10n/                     translations (app_en.arb, app_it.arb)
test/                       automated tests
```

## Run it

With Flutter installed and an Android phone connected (USB debugging on):

```
flutter pub get
flutter run
```

Run the tests with `flutter test`.

To build a small APK to share with friends, make one per processor type and send the `arm64-v8a` one (it fits almost every phone from the last ten years):

```
flutter build apk --release --split-per-abi
```

To measure how fast the app opens on your phone, run `flutter run --profile --trace-startup`: the times are written to `build/start_up_info.json` (`timeToFirstFrameMicros` is what you feel).

For Google Play, build an app bundle with `flutter build appbundle`: the store then sends each phone only what it needs.

## Translations

Texts live in `lib/l10n/app_en.arb` (English, the reference) and `lib/l10n/app_it.arb` (Italian). After changing them, run `flutter gen-l10n`.
