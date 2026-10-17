import 'package:flutter/material.dart';

import 'app_navigation.dart';
import 'style.dart';

/// Low End's look, in one place: change a colour, a radius or a font weight
/// here and every screen follows, like the variables of a CSS stylesheet.
///
/// The Orchestra (docs/tema-orchestra.md): a neutral ground, warm grey in
/// light and ebony in dark, and one flat accent per tab, the colour of a
/// material of the orchestra: brass, rosewood, silver ([LowEndTheme.accented]). The
/// wood names of the palette are what it grew from.
abstract final class Palette {
  // Signature: PANTONE 17-1230 Mocha Mousse.
  static const mochaMousse = Color(0xFFA47864);

  // Light woods.
  static const maple = Color(0xFFF1F0EE);
  static const mapleShade1 = Color(0xFFEAE8E5);
  static const mapleShade2 = Color(0xFFE2E0DC);
  static const mapleShade3 = Color(0xFFD9D6D1);
  static const spruce = Color(0xFFDCD4C0);

  // Dark woods.
  static const ebony = Color(0xFF141312);
  static const ebonyShade1 = Color(0xFF1C1B19);
  static const ebonyShade2 = Color(0xFF262422);
  static const ebonyShade3 = Color(0xFF312F2C);
  static const walnut = Color(0xFF5A3A2A);
  static const walnutDeep = Color(0xFF2B1D16);
  static const rosewood = Color(0xFF6E4B3A);

  // Text on wood.
  static const inkOnLight = Color(0xFF1E1C1A);
  static const inkOnLightMuted = Color(0xFF57534E);
  static const inkOnDark = Color(0xFFEFEDEA);
  static const inkOnDarkMuted = Color(0xFFC9C5BF);
  static const mochaLight = Color(0xFFE2BFA9);

  // Lines.
  static const grainLight = Color(0xFF837D76);
  static const grainLightSoft = Color(0xFFD3D0CB);
  static const grainDark = Color(0xFF96918A);
  static const grainDarkSoft = Color(0xFF45423E);

  // Brass, for the occasional highlight.
  static const brassDeep = Color(0xFF8A6508);
  static const brass = Color(0xFF7A5C1E);
  static const brassLight = Color(0xFFE3B84A);

  // Tuner verdicts: green, orange and a pure red, far from the brass and
  // the rosewood of the tabs, so a verdict never reads as a tab's colour.
  static const inTuneLight = Color(0xFF2E6B3A);
  static const inTuneDark = Color(0xFF8FD19E);
  static const closeLight = Color(0xFFA64B00);
  static const closeDark = Color(0xFFFFA05A);
  static const offLight = Color(0xFFC62828);
  static const offDark = Color(0xFFFF8A80);
}

/// Colours the Material scheme has no name for.
@immutable
class LowEndColors extends ThemeExtension<LowEndColors> {
  const LowEndColors({
    required this.inTune,
    required this.close,
    required this.off,
    required this.strobeBackground,
    required this.downbeat,
  });

  /// Within a few cents.
  final Color inTune;

  /// Within 15 cents.
  final Color close;

  /// Further off.
  final Color off;

  final Color strobeBackground;

  /// The first beat of the bar on the metronome's ring.
  final Color downbeat;

  static LowEndColors of(BuildContext context) =>
      Theme.of(context).extension<LowEndColors>()!;

  @override
  LowEndColors copyWith({
    Color? inTune,
    Color? close,
    Color? off,
    Color? strobeBackground,
    Color? downbeat,
  }) => LowEndColors(
    inTune: inTune ?? this.inTune,
    close: close ?? this.close,
    off: off ?? this.off,
    strobeBackground: strobeBackground ?? this.strobeBackground,
    downbeat: downbeat ?? this.downbeat,
  );

  @override
  LowEndColors lerp(LowEndColors? other, double t) {
    if (other == null) return this;
    return LowEndColors(
      inTune: Color.lerp(inTune, other.inTune, t)!,
      close: Color.lerp(close, other.close, t)!,
      off: Color.lerp(off, other.off, t)!,
      strobeBackground: Color.lerp(
        strobeBackground,
        other.strobeBackground,
        t,
      )!,
      downbeat: Color.lerp(downbeat, other.downbeat, t)!,
    );
  }
}

abstract final class LowEndTheme {
  static const radius = LowEndShape.radius;

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Palette.brassDeep,
    onPrimary: Colors.white,
    primaryContainer: Palette.spruce,
    onPrimaryContainer: Color(0xFF3A2A03),
    secondary: Palette.mochaMousse,
    onSecondary: Palette.walnutDeep,
    secondaryContainer: Palette.mapleShade3,
    onSecondaryContainer: Palette.walnutDeep,
    tertiary: Palette.brass,
    onTertiary: Colors.white,
    error: Palette.offLight,
    onError: Colors.white,
    surface: Palette.maple,
    onSurface: Palette.inkOnLight,
    onSurfaceVariant: Palette.inkOnLightMuted,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Palette.mapleShade1,
    surfaceContainer: Palette.mapleShade1,
    surfaceContainerHigh: Palette.mapleShade2,
    surfaceContainerHighest: Palette.mapleShade3,
    outline: Palette.grainLight,
    outlineVariant: Palette.grainLightSoft,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Palette.brassLight,
    onPrimary: Palette.walnutDeep,
    primaryContainer: Palette.rosewood,
    onPrimaryContainer: Palette.inkOnDark,
    secondary: Palette.mochaMousse,
    onSecondary: Palette.walnutDeep,
    secondaryContainer: Palette.ebonyShade3,
    onSecondaryContainer: Palette.inkOnDark,
    tertiary: Palette.brassLight,
    onTertiary: Palette.walnutDeep,
    error: Palette.offDark,
    onError: Palette.walnutDeep,
    surface: Palette.ebony,
    onSurface: Palette.inkOnDark,
    onSurfaceVariant: Palette.inkOnDarkMuted,
    surfaceContainerLowest: Colors.black,
    surfaceContainerLow: Palette.ebonyShade1,
    surfaceContainer: Palette.ebonyShade1,
    surfaceContainerHigh: Palette.ebonyShade2,
    surfaceContainerHighest: Palette.ebonyShade3,
    outline: Palette.grainDark,
    outlineVariant: Palette.grainDarkSoft,
  );

  static final light = _build(
    _lightScheme,
    const LowEndColors(
      inTune: Palette.inTuneLight,
      close: Palette.closeLight,
      off: Palette.offLight,
      strobeBackground: Palette.mapleShade2,
      downbeat: Palette.brassDeep,
    ),
  );

  static final dark = _build(
    _darkScheme,
    const LowEndColors(
      inTune: Palette.inTuneDark,
      close: Palette.closeDark,
      off: Palette.offDark,
      strobeBackground: Palette.ebonyShade2,
      downbeat: Palette.brassLight,
    ),
  );

  /// [base] (light or dark) with the accent of [section]. The background
  /// and the bar stay neutral; what is tinted is what belongs to the tab:
  /// the dial's disc, rings and segments, borders, buttons, the second voice
  /// of a chord and the tab's own pill. Verdict colours (green, ochre, red)
  /// are never touched.
  static ThemeData accented(ThemeData base, AppSection section) {
    final dark = base.brightness == Brightness.dark;
    final key = (dark, section);
    return _accented[key] ??= () {
      final spec = _accent[section]!;
      final scheme = base.colorScheme;
      final accent = dark ? spec.dark : spec.light;
      // The accent mixed into the background: the more of it, the stronger.
      Color tint(double amount) => Color.lerp(scheme.surface, accent, amount)!;
      final container = tint(0.2);
      final chord = tint(0.55);
      final extra = base.extension<LowEndColors>()!;
      return _build(
        scheme.copyWith(
          primary: accent,
          primaryContainer: container,
          onPrimaryContainer: dark ? Palette.inkOnDark : Palette.inkOnLight,
          // The selected tab's pill.
          secondaryContainer: container,
          onSecondaryContainer: dark ? Palette.inkOnDark : Palette.inkOnLight,
          secondary: chord,
          onSecondary: _readableOn(chord),
          // Borders, and the lit beats and the tuner's segments: 3 : 1 on the
          // disc, which in light takes more of the accent.
          outline: tint(dark ? 0.75 : 0.9),
          outlineVariant: tint(0.26),
          onSurfaceVariant: Color.lerp(
            dark ? Palette.inkOnDarkMuted : Palette.inkOnLightMuted,
            accent,
            0.25,
          ),
        ),
        extra.copyWith(
          strobeBackground: tint(0.1),
          // The "one" is the accent at full strength, drawn thicker; the
          // other beats are the accent too, a step softer.
          downbeat: accent,
        ),
      );
    }();
  }

  static final _accented = <(bool, AppSection), ThemeData>{};

  /// The Orchestra: brass for the metronome, rosewood for the harmony, silver
  /// for the tuner. Each accent is flat; every other shade of a tab is the
  /// accent mixed into the neutral background, so the three tabs share one
  /// look and differ by one colour.
  static const _accent = {
    AppSection.metronome: _Accent(
      light: Color(0xFF8A6508),
      dark: Color(0xFFE3B84A),
    ),
    AppSection.drone: _Accent(
      light: Color(0xFF8A4A33),
      dark: Color(0xFFD88F6E),
    ),
    AppSection.tuner: _Accent(
      light: Color(0xFF5E6B7A),
      dark: Color(0xFFB4C0CF),
    ),
  };

  static ThemeData _build(ColorScheme scheme, LowEndColors colors) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return ThemeData(
      // Edwin (SIL OFL), the text font of MuseScore, bundled in assets/fonts;
      // it has the ♭ and ♯. The ♩, which it lacks, comes from Noto Music.
      fontFamily: 'Edwin',
      fontFamilyFallback: const ['NotoMusic'],
      colorScheme: scheme,
      textTheme: LowEndType.textTheme,
      // The name written on the border of a field is never under the
      // smallest size: it is drawn at three quarters of this.
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelStyle: TextStyle(fontSize: LowEndType.small / 0.75),
      ),
      scaffoldBackgroundColor: scheme.surface,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: Typography.material2021().black.titleLarge?.copyWith(
          fontFamily: 'Edwin',
          fontFamilyFallback: const ['NotoMusic'],
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: LowEndType.small,
            color: scheme.onSurface,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: shape),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          // The choices not taken in the muted ink: the colour marks the one
          // that is.
          foregroundColor: scheme.onSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: scheme.primary,
        inactiveTrackColor: scheme.outlineVariant,
      ),
    );
  }
}

/// The accent of one tab, flat, in light and dark.
class _Accent {
  const _Accent({required this.light, required this.dark});

  final Color light;
  final Color dark;
}

/// The dark or the light ink, whichever reads better on [background].
Color _readableOn(Color background) {
  double ratio(Color a, Color b) {
    final l1 = a.computeLuminance(), l2 = b.computeLuminance();
    final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
    return (hi + 0.05) / (lo + 0.05);
  }

  return ratio(background, Palette.inkOnLight) >=
          ratio(background, Palette.inkOnDark)
      ? Palette.inkOnLight
      : Palette.inkOnDark;
}
