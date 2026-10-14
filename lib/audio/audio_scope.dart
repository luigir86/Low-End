import 'package:flutter/widgets.dart';

import '../actions/app_actions.dart';
import '../app/app_navigation.dart';
import '../features/tuner/drone/drone_controller.dart';
import '../features/tuner/tuner_controller.dart';

/// Makes the app's sound sources, the tuner listening to the microphone,
/// the navigation and the action layer available to every screen.
class AudioScope extends InheritedWidget {
  const AudioScope({
    super.key,
    required this.drone,
    required this.tuner,
    required this.navigation,
    required this.actions,
    required super.child,
  });

  final DroneController drone;
  final TunerController tuner;
  final AppNavigation navigation;
  final AppActions actions;

  static AudioScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AudioScope>();
    assert(scope != null, 'No AudioScope above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AudioScope oldWidget) =>
      drone != oldWidget.drone ||
      tuner != oldWidget.tuner ||
      navigation != oldWidget.navigation ||
      actions != oldWidget.actions;
}
