# Low End

Low End is a mobile app for double bass and electric bass players, built with [Flutter](https://flutter.dev) for Android and iOS.

## Planned features

1. **Tuner** for double bass (orchestral and solo tuning, C extension, 5-string) and electric bass (4, 5 and 6 strings, drop tunings).
2. **Drone**: a sustained pure tone to practise intonation on, with optional pure fifth and octave, inside the Tuner section and also reachable from the Metronome.
3. **Metronome** with accents, subdivisions and a speed trainer.
4. **PDF library** for sheet music, set lists and annotations (later: the app starts with the tuner, drone and metronome).
5. **PDF to MusicXML** conversion (beta, server-side optical music recognition).
6. **MIDI playback** of converted scores, at the real sounding octave.

The app is available in English and Italian.

The tuner listens through the microphone only while you ask it to, and stops as soon as you leave it or the app goes to the background. It finds the note with the YIN algorithm (`lib/audio/pitch_detector.dart`), down to the low B of five-string basses.

While any sound plays, its tab shows a pulsing dot and a strip above the navigation bar offers a stop button for it.

## Project structure

```
lib/
  main.dart                 entry point
  app/                      app setup and main navigation
  features/
    tuner/                  tuner screen and logic
    metronome/              metronome screen and logic
  audio/                    pitch maths and sound output
  widgets/                  shared UI pieces
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

## Translations

Texts live in `lib/l10n/app_en.arb` (English, the reference) and `lib/l10n/app_it.arb` (Italian). After changing them, run `flutter gen-l10n`.
