import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/app_navigation.dart';
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

  // WCAG contrast ratio of two colours.
  double contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  for (final (name, theme) in [
    ('light', LowEndTheme.light),
    ('dark', LowEndTheme.dark),
  ]) {
    test('$name: each tab accent keeps its contrast', () {
      for (final section in AppSection.values) {
        final c = LowEndTheme.accented(theme, section).colorScheme;
        // Text and shapes in the accent, on the surface and on the pill.
        expect(contrast(c.primary, c.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
        expect(
          contrast(c.onSecondaryContainer, c.secondaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(c.secondaryContainer, c.surface), greaterThan(1.1));
        // What the tab tints: muted text, the second voice of a chord, the
        // borders and the verdicts, on the tab's disc and surface.
        final extra = LowEndTheme.accented(
          theme,
          section,
        ).extension<LowEndColors>()!;
        expect(
          contrast(c.onSurfaceVariant, c.surface),
          greaterThanOrEqualTo(4.5),
        );
        // The notes of a chord exist only on the harmony tab: there 4.5; the
        // other tabs keep the pair for bold text at 4 or more.
        expect(
          contrast(c.onSecondary, c.secondary),
          greaterThanOrEqualTo(section == AppSection.drone ? 4.5 : 4.0),
        );
        expect(contrast(c.outline, c.surface), greaterThanOrEqualTo(3));
        expect(
          contrast(c.outline, extra.strobeBackground),
          greaterThanOrEqualTo(3),
        );
        for (final v in [extra.inTune, extra.close, extra.off]) {
          expect(contrast(v, extra.strobeBackground), greaterThanOrEqualTo(3));
          expect(contrast(v, c.surface), greaterThanOrEqualTo(3));
        }
      }
    });

    test('$name: the dial reads at a glance (WCAG 1.4.11)', () {
      final colors = theme.colorScheme;
      final extra = theme.extension<LowEndColors>()!;
      final disc = extra.strobeBackground;
      // The edge of a segment that is off, on the disc.
      expect(contrast(colors.outline, disc), greaterThanOrEqualTo(3));
      // The "one", the accent itself (it also stands out by being wider),
      // against the disc.
      expect(extra.downbeat, colors.primary);
      expect(contrast(extra.downbeat, disc), greaterThanOrEqualTo(3));
      // The other lit beats, a step softer, against the disc.
      expect(contrast(colors.outline, disc), greaterThanOrEqualTo(3));
    });
  }

  // TAP is filled to say it is a button to press (docs/style.md): its text
  // must read on the fill.
  for (final (name, theme) in [
    ('light', LowEndTheme.light),
    ('dark', LowEndTheme.dark),
  ]) {
    test('$name: TAP reads on its filled chip', () {
      final colors = theme.colorScheme;
      expect(
        contrast(colors.onPrimaryContainer, colors.primaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      // And the chip stands out from the page.
      expect(
        contrast(colors.primaryContainer, colors.surface),
        greaterThan(1.1),
      );
    });
  }

  test('the signature colour is PANTONE 17-1230 Mocha Mousse', () {
    expect(_hex(Palette.mochaMousse), '#A47864');
    expect(LowEndTheme.light.colorScheme.secondary, Palette.mochaMousse);
  });
}
