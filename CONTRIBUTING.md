# Contributing to Low End

Thanks for helping! Low End is a small, free app for musicians. Bug reports, translations and code are all welcome.

## Reporting a problem or an idea

Open an issue at https://github.com/luigir86/Low-End/issues. For tuner problems, say which phone you use, which instrument and note, and whether you used the phone's microphone or an external one.

## Changing the code

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and fork the repository.
2. Make your change on a new branch.
3. Before opening a pull request, run:

   ```
   dart format lib test
   flutter analyze
   flutter test
   ```

4. Open a pull request explaining what changes for the player.

Keep the app light: please discuss in an issue before adding a new package, and avoid anything that tracks users or needs the internet.

## Look and feel

All colours, shapes and text styles live in `lib/app/theme.dart`: the wood palette (maple, walnut, ebony) with PANTONE 17-1230 Mocha Mousse as the signature colour, and the tuner colours. Screens take them from the theme (`Theme.of(context)`, `LowEndColors.of(context)`) and never write a colour of their own. If you change the background colours, change `android/app/src/main/res/values*/colors.xml` too: `test/theme_test.dart` checks they match.

## Accessibility

Every screen must work with TalkBack/VoiceOver, with the largest text size and without relying on colour alone. `test/accessibility_test.dart` checks touch targets, labels and contrast: add new screens to it.

## Translations

Texts live in `lib/l10n/app_en.arb` (English, the reference) and `lib/l10n/app_it.arb` (Italian). To add a language, copy `app_en.arb` to `app_<code>.arb`, translate the values and run `flutter gen-l10n`.

## Licence

By contributing you agree that your work is released under the [MIT License](LICENSE).
