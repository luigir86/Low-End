import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/theme.dart';

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  final theme = LowEndTheme.dark;
  final c = theme.colorScheme;
  final extra = theme.extension<LowEndColors>()!;

  // Android draws the launch screen before Flutter starts; if its colour
  // drifts from the theme, opening the app flashes. The app is always dark,
  // so there is one launch colour and no night variant.
  test('the launch screen colour matches the theme background', () {
    final launch = RegExp(r'#[0-9A-Fa-f]{6}')
        .firstMatch(
          File('android/app/src/main/res/values/colors.xml').readAsStringSync(),
        )![0]!
        .toUpperCase();
    expect(launch, _hex(c.surface));
    expect(
      Directory('android/app/src/main/res/values-night').existsSync(),
      isFalse,
    );
  });

  // WCAG contrast ratio of two colours.
  double contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  test('the bronze keeps its contrast', () {
    // Text and shapes in the accent, on the surface and on the pill.
    expect(contrast(c.primary, c.surface), greaterThanOrEqualTo(4.5));
    expect(contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
    expect(
      contrast(c.onSecondaryContainer, c.secondaryContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(contrast(c.secondaryContainer, c.surface), greaterThan(1.1));
    expect(contrast(c.onSurfaceVariant, c.surface), greaterThanOrEqualTo(4.5));
    // The notes of a chord on the circle of fifths.
    expect(contrast(c.onSecondary, c.secondary), greaterThanOrEqualTo(4.5));
    expect(contrast(c.outline, c.surface), greaterThanOrEqualTo(3));
    expect(
      contrast(c.outline, extra.strobeBackground),
      greaterThanOrEqualTo(3),
    );
    expect(
      contrast(extra.strobeSegments, extra.strobeBackground),
      greaterThanOrEqualTo(3),
    );
    for (final v in [extra.inTune, extra.close, extra.off]) {
      expect(contrast(v, extra.strobeBackground), greaterThanOrEqualTo(3));
      expect(contrast(v, c.surface), greaterThanOrEqualTo(3));
    }
  });

  test('the verdicts are not the bronze', () {
    // Told apart by hue, not only by lightness: at least 20 degrees.
    double hue(Color x) => HSLColor.fromColor(x).hue;
    for (final v in [extra.inTune, extra.close, extra.off]) {
      final d = (hue(v) - hue(c.primary)).abs();
      expect(math.min(d, 360 - d), greaterThanOrEqualTo(20));
    }
  });

  test('the dial reads at a glance (WCAG 1.4.11)', () {
    final disc = extra.strobeBackground;
    // The edge of a segment that is off, on the disc.
    expect(contrast(c.outline, disc), greaterThanOrEqualTo(3));
    // The "one", the accent itself (it also stands out by being wider),
    // against the disc.
    expect(extra.downbeat, c.primary);
    expect(contrast(extra.downbeat, disc), greaterThanOrEqualTo(3));
  });

  // TAP is filled to say it is a button to press (docs/style.md): its text
  // must read on the fill.
  test('TAP reads on its filled chip', () {
    expect(
      contrast(c.onPrimaryContainer, c.primaryContainer),
      greaterThanOrEqualTo(4.5),
    );
    // And the chip stands out from the page.
    expect(contrast(c.primaryContainer, c.surface), greaterThan(1.1));
  });

  test('the accent is the bronze of the icon', () {
    expect(_hex(Palette.bronze), '#D4A373');
    expect(c.primary, Palette.bronze);
  });
}
