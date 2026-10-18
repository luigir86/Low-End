# Low End (Flutter, Android)

A free metronome, piano harmony ("Armonia", `drone` in the code) and tuner for musicians. No backend, no network, no tracking. Architecture: `docs/architecture.md`; actions for assistants: `docs/llm.md`.

## Commands

```
flutter pub get
flutter gen-l10n          # after editing lib/l10n/*.arb (generated Dart files are committed)
dart format lib test      # always before committing
flutter analyze
flutter test              # or one file: flutter test test/app_actions_test.dart
flutter test test/app_actions_test.dart --update-goldens   # regenerates docs/llm-actions.json
```

## Structure

- `lib/app/` shell, settings, theme (always dark, bronze), guide; `lib/features/{metronome,tuner,tuner/drone}/` controllers + screens; `lib/audio/` sound and microphone behind interfaces with silent/fake twins for tests; `lib/actions/app_actions.dart` the action layer; `lib/l10n/` English (reference) and Italian.
- State is plain `ChangeNotifier` controllers passed by `AudioScope`; no state-management package.

## Product rules (keep them true)

- Three sections; tabs only navigate. Each section starts/stops its own sound from the centre of its dial. No balance setting.
- Entering the tuner stops nothing; touching the tuner dial (or `tuner_start`) pauses the metronome and Harmony with a "Resume" snackbar.
- Harmony started while the click plays enters on the metronome's bar line with a countdown (and vice versa).
- "Lock gestures" only disables swiping between sections.

## Conventions

- Anything the player can do must also be an action in `lib/actions/app_actions.dart`; if you change an action or its description, regenerate `docs/llm-actions.json` and update `docs/llm.md`.
- Every user-visible text goes in both `.arb` files; never hard-code strings or colours (use the theme).
- Add new screens to `test/accessibility_test.dart`. Tests use the silent/fake outputs, no phone needed.

## Known traps

- Files use CRLF on this Windows setup (`core.autocrlf=true`): edit tools that match multi-line text may fail; the actions golden test tolerates CRLF.
- The repo lives in OneDrive: syncing can lock files in `build/` or `.dart_tool/`; retry or pause sync if a build fails on file access.
- `lib/l10n/app_localizations*.dart` are generated: change the `.arb` and run `flutter gen-l10n`, never edit them by hand.
- Python is not installed; use Dart or shell for scripts. Flutter is in `C:\src\flutter\bin`.
- Work in the worktree/branch you were given; do not stash or reset.
