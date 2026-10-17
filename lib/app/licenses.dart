import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the licences of the fonts and the piano and drum recordings to the page that
/// the About dialog opens, next to the ones Flutter collects for the code
/// packages. They are read only when that page is opened.
void registerAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Edwin',
    ], await rootBundle.loadString('assets/fonts/OFL-Edwin.txt'));
    yield LicenseEntryWithLineBreaks([
      'Noto Music',
    ], await rootBundle.loadString('assets/fonts/OFL-NotoMusic.txt'));
    yield const LicenseEntryWithLineBreaks(
      ['Salamander Grand Piano V3'],
      'Piano recordings by Alexander Holm, released into the public domain '
      'on 4 March 2022. No licence is needed to use them.',
    );
    yield const LicenseEntryWithLineBreaks(
      ['Versilian Community Sample Library (drums)'],
      'Drum recordings (suspended cymbal, bass drum, snare drum, hi-hat) from '
      'the Versilian Community Sample Library by Versilian Studios LLC, '
      'released under the Creative Commons CC0 1.0 Universal public domain '
      'dedication: https://github.com/sgossner/VCSL. No licence is needed to '
      'use them.',
    );
  });
}
