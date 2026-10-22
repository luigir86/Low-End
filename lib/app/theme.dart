import 'package:flutter/material.dart';

import 'style.dart';

/// Low End's look, in one place: change a colour, a radius or a font weight
/// here and every screen follows, like the variables of a CSS stylesheet.
///
/// Bronze on ebony (docs/tema-bronzo.md): always dark, one flat accent for
/// the whole app, the bronze of the lion on the icon. Every other shade is
/// that bronze mixed into the ebony ground.
abstract final class Palette {
  /// The accent: the honey bronze of the lion on the icon.
  static const bronze = Color(0xFFD4A373);

  // The ground, from the darkest up.
  static const ebony = Color(0xFF141312);
  static const ebonyShade1 = Color(0xFF1C1B19);
  static const ebonyShade2 = Color(0xFF262422);
  static const ebonyShade3 = Color(0xFF312F2C);
  static const walnutDeep = Color(0xFF2B1D16);

  // Text.
  static const inkOnLight = Color(0xFF1E1C1A);
  static const inkOnDark = Color(0xFFEFEDEA);
  static const inkOnDarkMuted = Color(0xFFC9C5BF);

  // Tuner verdicts: green, amber and a pure red, told apart from the bronze
  // by their hue, so a verdict never reads as the app's own colour.
  static const inTune = Color(0xFF8FD19E);
  static const close = Color(0xFFF2DA4E);
  static const off = Color(0xFFFF5F56);
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

  /// The bronze mixed into the ebony: the more of it, the stronger.
  static Color tint(double amount) =>
      Color.lerp(Palette.ebony, Palette.bronze, amount)!;

  /// The one theme: dark, bronze on ebony. There is no light theme and no
  /// choice of theme (docs/tema-bronzo.md).
  static final dark = () {
    final container = tint(0.2);
    // 3 : 1 on the disc (the strobe and the beats are drawn in it too) and
    // 4.5 : 1 under the light ink of the note names.
    final chord = tint(0.58);
    return _build(
      ColorScheme(
        brightness: Brightness.dark,
        primary: Palette.bronze,
        onPrimary: Palette.walnutDeep,
        // TAP, the chosen half of a switch and the selected tab's pill.
        primaryContainer: container,
        onPrimaryContainer: Palette.inkOnDark,
        // The rest of a chord on the circle of fifths, and the beats after
        // the "one" on the metronome.
        secondary: chord,
        onSecondary: _readableOn(chord),
        secondaryContainer: container,
        onSecondaryContainer: Palette.inkOnDark,
        tertiary: Palette.bronze,
        onTertiary: Palette.walnutDeep,
        error: Palette.off,
        onError: Palette.walnutDeep,
        surface: Palette.ebony,
        onSurface: Palette.inkOnDark,
        onSurfaceVariant: Color.lerp(
          Palette.inkOnDarkMuted,
          Palette.bronze,
          0.25,
        )!,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: Palette.ebonyShade1,
        surfaceContainer: Palette.ebonyShade1,
        surfaceContainerHigh: Palette.ebonyShade2,
        surfaceContainerHighest: Palette.ebonyShade3,
        // Borders: 3 : 1 on the disc.
        outline: tint(0.75),
        // Keys and beats that are off.
        outlineVariant: tint(0.26),
      ),
      LowEndColors(
        inTune: Palette.inTune,
        close: Palette.close,
        off: Palette.off,
        strobeBackground: tint(0.1),
        // The "one" is the accent at full strength, drawn thicker; the other
        // beats take the colour of a chord's other notes (secondary).
        downbeat: Palette.bronze,
      ),
    );
  }();

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
          fontWeight: FontWeight.w700,
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
                : FontWeight.w400,
          ),
        ),
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
      ),
      // The tabs in landscape, the same three destinations as the bottom
      // bar, in the same colours and text.
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        minWidth: 96,
        selectedLabelTextStyle: TextStyle(
          fontSize: LowEndType.small,
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: LowEndType.small,
          color: scheme.onSurface,
        ),
      ),
      // The dot on the tab of a section that is playing: the accent, not
      // the red of an error.
      badgeTheme: BadgeThemeData(backgroundColor: scheme.primary),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        elevation: 0,
      ),
      // The menu of every list of choices (`showChoiceMenu`): round corners
      // like the cards, on the raised surface, with no tint.
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        elevation: 3,
        menuPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: shape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: shape),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          // As high as a finger (the harmony's switch under its dial is
          // taller still, in its own style).
          minimumSize: const Size(0, 48),
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
