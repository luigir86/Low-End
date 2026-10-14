# Low End

Low End is a mobile app for double bass and electric bass players, built with [Flutter](https://flutter.dev) for Android and iOS.

## Planned features

1. **Tuner** for double bass (orchestral and solo tuning, C extension, 5-string) and electric bass (4, 5 and 6 strings, drop tunings).
2. **Metronome** with accents, subdivisions and a speed trainer.
3. **PDF library** for sheet music, set lists and annotations.
4. **PDF to MusicXML** conversion (beta, server-side optical music recognition).
5. **MIDI playback** of converted scores, at the real sounding octave.

The app is available in English and Italian.

## Project structure

```
lib/
  main.dart                 entry point
  app/                      app setup and main navigation
  features/
    tuner/                  tuner screen and logic
    metronome/              metronome screen and logic
    library/                PDF library
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
