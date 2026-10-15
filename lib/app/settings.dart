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
}
