import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/pitch.dart';

/// How note names are chosen: from the app language, or fixed.
enum NoteNaming { auto, solfege, letters }

/// How the twelve notes are laid round the harmony circle: by fifths, or in
/// semitones, as on the fingerboard.
enum CircleLayout { fifths, chromatic }

/// The player's preferences, kept on the phone between launches.
class AppSettings extends ChangeNotifier {
  /// Settings that are not saved anywhere; used in tests.
  AppSettings() : _prefs = null;

  AppSettings._(this._prefs) {
    final prefs = _prefs!;
    // Each value is checked for its type as well: one saved by another
    // build or edited by hand must fall back to the default, not stop the
    // app from opening.
    final language = _read<String>(prefs, _languageKey);
    _languageCode = supportedLanguages.contains(language) ? language : null;
    _naming =
        NoteNaming.values.asNameMap()[_read<String>(prefs, _namingKey)] ??
        NoteNaming.auto;
    final a4 = _read<num>(prefs, _a4Key)?.toDouble();
    _a4 = referencePitches.contains(a4) ? a4! : 440;
    final balance = _read<num>(prefs, _balanceKey)?.toDouble();
    _balance = balance != null && balance.isFinite
        ? balance.clamp(-1.0, 1.0)
        : 0;
    _themeMode =
        ThemeMode.values.asNameMap()[_read<String>(prefs, _themeKey)] ??
        ThemeMode.system;
    _circleLayout =
        CircleLayout.values.asNameMap()[_read<String>(
          prefs,
          _circleLayoutKey,
        )] ??
        CircleLayout.fifths;
    _keepScreenOn = _read<bool>(prefs, _keepScreenOnKey) ?? true;
    _seenGuide = _read<bool>(prefs, _seenGuideKey) ?? false;
  }

  /// Reads the saved settings.
  static Future<AppSettings> load() async =>
      AppSettings._(await SharedPreferences.getInstance());

  static const supportedLanguages = ['en', 'it'];
  static const _languageKey = 'language';
  static const _namingKey = 'note_names';
  static const _a4Key = 'reference_pitch';
  static const _balanceKey = 'balance';
  static const _themeKey = 'theme';
  static const _keepScreenOnKey = 'keep_screen_on';
  static const _seenGuideKey = 'seen_guide';
  static const _circleLayoutKey = 'circle_layout';

  final SharedPreferences? _prefs;
  String? _languageCode;
  NoteNaming _naming = NoteNaming.auto;
  double _a4 = 440;

  /// The value saved under [key] if it has type [T], otherwise null.
  static T? _read<T>(SharedPreferences prefs, String key) {
    final value = prefs.get(key);
    return value is T ? value : null;
  }

  /// Saves in the background: the setting already applies, and a failed
  /// write only means it is forgotten at the next launch.
  void _save(Future<bool>? write) {
    write?.catchError((Object error) {
      debugPrint('Settings could not be saved: $error');
      return false;
    });
  }

  /// 'en' or 'it', or null to follow the phone.
  String? get languageCode => _languageCode;
  NoteNaming get naming => _naming;

  /// Frequency of A4 in Hz, shared by the tuner and the drone.
  double get a4 => _a4;

  /// The locale to show the app in, or null to follow the phone.
  Locale? get locale => _languageCode == null ? null : Locale(_languageCode!);

  /// The note names to use when the app shows [appLocale].
  NoteNames noteNames(Locale appLocale) => switch (_naming) {
    NoteNaming.solfege => NoteNames.solfege,
    NoteNaming.letters => NoteNames.letters,
    NoteNaming.auto =>
      appLocale.languageCode == 'it' ? NoteNames.solfege : NoteNames.letters,
  };

  void setLanguage(String? code) {
    assert(code == null || supportedLanguages.contains(code));
    _languageCode = code;
    _save(
      code == null
          ? _prefs?.remove(_languageKey)
          : _prefs?.setString(_languageKey, code),
    );
    notifyListeners();
  }

  void setNaming(NoteNaming naming) {
    _naming = naming;
    _save(_prefs?.setString(_namingKey, naming.name));
    notifyListeners();
  }

  void setReferencePitch(double hz) {
    assert(referencePitches.contains(hz));
    _a4 = hz;
    _save(_prefs?.setDouble(_a4Key, hz));
    notifyListeners();
  }

  CircleLayout _circleLayout = CircleLayout.fifths;
  ThemeMode _themeMode = ThemeMode.system;
  bool _keepScreenOn = true;

  // Unsaved settings (tests) have nothing to teach: the guide is for the
  // first launch of the real app.
  bool _seenGuide = true;

  /// Whether the guide to the gestures has been shown once already.
  bool get seenGuide => _seenGuide;

  void markGuideSeen() {
    if (_seenGuide) return;
    _seenGuide = true;
    _save(_prefs?.setBool(_seenGuideKey, true));
  }

  /// Light, dark, or the phone's own setting: dark can be forced on a dark
  /// stage whatever the phone is set to.
  ThemeMode get themeMode => _themeMode;

  /// Whether the screen stays on while something plays or the tuner
  /// listens.
  bool get keepScreenOn => _keepScreenOn;

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    _save(_prefs?.setString(_themeKey, mode.name));
    notifyListeners();
  }

  /// The order of the notes on the harmony circle.
  CircleLayout get circleLayout => _circleLayout;

  void setCircleLayout(CircleLayout layout) {
    if (layout == _circleLayout) return;
    _circleLayout = layout;
    _save(_prefs?.setString(_circleLayoutKey, layout.name));
    notifyListeners();
  }

  void setKeepScreenOn(bool value) {
    if (value == _keepScreenOn) return;
    _keepScreenOn = value;
    _save(_prefs?.setBool(_keepScreenOnKey, value));
    notifyListeners();
  }

  double _balance = 0;

  /// The balance between the metronome and the drone, from -1 (only the
  /// metronome) through 0 (both at full level) to 1 (only the drone), like
  /// a mixer's crossfader. How loud both are overall is the phone's volume.
  double get balance => _balance;

  /// Level of the metronome from the balance, 0 to 1.
  double get metronomeLevel => _balance <= 0 ? 1 : 1 - _balance;

  /// Level of the drone from the balance, 0 to 1.
  double get droneLevel => _balance >= 0 ? 1 : 1 + _balance;

  void setBalance(double balance) {
    final value = balance.clamp(-1.0, 1.0);
    if (value == _balance) return;
    _balance = value;
    _save(_prefs?.setDouble(_balanceKey, value));
    notifyListeners();
  }
}
