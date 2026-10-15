import 'package:flutter/foundation.dart';

/// The sections of the app, one per tab, in tab order.
enum AppSection { tuner, drone, metronome }

/// Which section is on screen. Kept outside the widgets so that taps and
/// actions from an assistant (see `lib/actions/`) move the app the same way.
class AppNavigation extends ChangeNotifier {
  AppSection _section = AppSection.tuner;

  AppSection get section => _section;

  /// The microphone may only listen while the tuner itself is on screen.
  bool get tunerVisible => _section == AppSection.tuner;

  void open(AppSection section) {
    if (section == _section) return;
    _section = section;
    notifyListeners();
  }
}
