import 'package:flutter/widgets.dart';

import '../features/tuner/drone/drone_controller.dart';
import '../features/tuner/tuner_controller.dart';

/// Makes the app's sound sources, and the tuner listening to the
/// microphone, available to every screen.
class AudioScope extends InheritedWidget {
  const AudioScope({
    super.key,
    required this.drone,
    required this.tuner,
    required super.child,
  });

  final DroneController drone;
  final TunerController tuner;

  static AudioScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AudioScope>();
    assert(scope != null, 'No AudioScope above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AudioScope oldWidget) =>
      drone != oldWidget.drone || tuner != oldWidget.tuner;
}
