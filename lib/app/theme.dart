import 'package:flutter/material.dart';

/// Low End's look, in one place: change a colour, a radius or a font weight
/// here and every screen follows, like the variables of a CSS stylesheet.
///
/// The palette is wood, the colour of a bass: maple for light surfaces,
/// walnut for dark ones and text, and PANTONE 17-1230 Mocha Mousse as the
/// signature colour. Pantone shades are printed colours; the values here are
/// their usual screen equivalents.
abstract final class Palette {
  // Signature: PANTONE 17-1230 Mocha Mousse.
  static const mochaMousse = Color(0xFFA47864);

  // Light woods.
  static const maple = Color(0xFFFBF6F1);
  static const mapleShade1 = Color(0xFFF5ECE4);
  static const mapleShade2 = Color(0xFFEFE3D8);
  static const mapleShade3 = Color(0xFFE8D9CB);
  static const spruce = Color(0xFFF1DED1);

  // Dark woods.
  static const ebony = Color(0xFF1B1411);
  static const ebonyShade1 = Color(0xFF241B17);
  static const ebonyShade2 = Color(0xFF2E231E);
  static const ebonyShade3 = Color(0xFF3A2D26);
  static const walnut = Color(0xFF5A3A2A);
  static const walnutDeep = Color(0xFF2B1D16);
  static const rosewood = Color(0xFF6E4B3A);

  // Text on wood.
  static const inkOnLight = Color(0xFF2B1E17);
  static const inkOnLightMuted = Color(0xFF5E4B40);
  static const inkOnDark = Color(0xFFF1E6DD);
  static const inkOnDarkMuted = Color(0xFFD4C3B7);
  static const mochaLight = Color(0xFFE2BFA9);

  // Lines.
  static const grainLight = Color(0xFF8A7365);
  static const grainLightSoft = Color(0xFFD9C8BA);
  static const grainDark = Color(0xFF9C8679);
  static const grainDarkSoft = Color(0xFF4E3F36);

  // Brass, for the occasional highlight.
  static const brass = Color(0xFF7A5C1E);
  static const brassLight = Color(0xFFE3C27A);

  // The metronome's "one": unlike the other beats in both tint and
  // lightness, so it shows out of the corner of an eye on a dark stage.
  static const downbeatLight = Color(0xFFB8440F);
  static const downbeatDark = Color(0xFFFFF4E0);

  // Tuner verdicts.
  static const inTuneLight = Color(0xFF2E6B3A);
  static const inTuneDark = Color(0xFF8FD19E);
  static const closeLight = Color(0xFF8A5A00);
  static const closeDark = Color(0xFFF1C66B);
  static const offLight = Color(0xFFA6322A);
  static const offDark = Color(0xFFFFB4A8);
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
  static const radius = 16.0;

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Palette.walnut,
    onPrimary: Colors.white,
    primaryContainer: Palette.spruce,
    onPrimaryContainer: Palette.walnutDeep,
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
    primary: Palette.mochaLight,
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
      downbeat: Palette.downbeatLight,
    ),
  );

  static final dark = _build(
    _darkScheme,
    const LowEndColors(
      inTune: Palette.inTuneDark,
      close: Palette.closeDark,
      off: Palette.offDark,
      strobeBackground: Palette.ebonyShade2,
      downbeat: Palette.downbeatDark,
    ),
  );

  static ThemeData _build(ColorScheme scheme, LowEndColors colors) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return ThemeData(
      // Edwin (SIL OFL), the text font of MuseScore, bundled in assets/fonts;
      // it has the ♭ and ♯. Barlow fills the few characters it lacks, and
      // the ♩ comes from Noto Music.
      fontFamily: 'Edwin',
      fontFamilyFallback: const ['Barlow', 'NotoMusic'],
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: Typography.material2021().black.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
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
