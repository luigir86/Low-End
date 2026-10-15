import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/pitch.dart';

/// How note names are chosen: from the app language, or fixed.
enum NoteNaming { auto, solfege, letters }

/// The player's preferences, kept on the phone between launches.
class AppSettings extends ChangeNotifier {
  /// Settings that are not saved anywhere; used in tests.
  AppSettings() : _prefs = null;

  AppSettings._(this._prefs) {
    final prefs = _prefs!;
    final language = prefs.getString(_languageKey);
    _languageCode = supportedLanguages.contains(language) ? language : null;
    _naming =
        NoteNaming.values.asNameMap()[prefs.getString(_namingKey)] ??
        NoteNaming.auto;
    final a4 = prefs.getDouble(_a4Key);
    _a4 = referencePitches.contains(a4) ? a4! : 440;
  }

  /// Reads the saved settings.
  static Future<AppSettings> load() async =>
      AppSettings._(await SharedPreferences.getInstance());

  static const supportedLanguages = ['en', 'it'];
  static const _languageKey = 'language';
  static const _namingKey = 'note_names';
  static const _a4Key = 'reference_pitch';

  final SharedPreferences? _prefs;
  String? _languageCode;
  NoteNaming _naming = NoteNaming.auto;
  double _a4 = 440;

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
    code == null
        ? _prefs?.remove(_languageKey)
        : _prefs?.setString(_languageKey, code);
    notifyListeners();
  }

  void setNaming(NoteNaming naming) {
    _naming = naming;
    _prefs?.setString(_namingKey, naming.name);
    notifyListeners();
  }

  void setReferencePitch(double hz) {
    assert(referencePitches.contains(hz));
    _a4 = hz;
    _prefs?.setDouble(_a4Key, hz);
    notifyListeners();
  }
}
