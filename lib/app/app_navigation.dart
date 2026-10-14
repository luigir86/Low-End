import 'package:flutter/foundation.dart';

/// The places the app can show: the two tuner modes and the metronome.
enum AppSection { tuner, drone, metronome }

/// Which section is on screen. Kept outside the widgets so that taps and
/// actions from an assistant (see `lib/actions/`) move the app the same way.
class AppNavigation extends ChangeNotifier {
  AppSection _section = AppSection.tuner;

  /// The tuner mode last shown, kept while the metronome is open so the
  /// Tuner tab comes back to it.
  AppSection _tunerMode = AppSection.tuner;

  AppSection get section => _section;
  AppSection get tunerMode => _tunerMode;

  /// The microphone may only listen while the tuner itself is on screen.
  bool get tunerVisible => _section == AppSection.tuner;

  void open(AppSection section) {
    if (section == _section) return;
    _section = section;
    if (section != AppSection.metronome) _tunerMode = section;
    notifyListeners();
  }

  /// Opens the Tuner tab in whichever mode it was last in.
  void openTunerTab() => open(_tunerMode);
}
