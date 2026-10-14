import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/theme.dart';

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  // Android draws the launch screen before Flutter starts; if its colour
  // drifts from the theme, opening the app flashes.
  test('the launch screen colours match the theme backgrounds', () {
    String launch(String folder) => RegExp(r'#[0-9A-Fa-f]{6}')
        .firstMatch(
          File('android/app/src/main/res/$folder/colors.xml')
              .readAsStringSync(),
        )![0]!
        .toUpperCase();
    expect(launch('values'), _hex(LowEndTheme.light.colorScheme.surface));
    expect(launch('values-night'), _hex(LowEndTheme.dark.colorScheme.surface));
  });

  test('the signature colour is PANTONE 17-1230 Mocha Mousse', () {
    expect(_hex(Palette.mochaMousse), '#A47864');
    expect(LowEndTheme.light.colorScheme.secondary, Palette.mochaMousse);
  });
}
