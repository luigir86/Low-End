import 'package:flutter/widgets.dart';

import '../features/tuner/drone/drone_controller.dart';

/// Makes the app's sound sources available to every screen.
class AudioScope extends InheritedWidget {
  const AudioScope({super.key, required this.drone, required super.child});

  final DroneController drone;

  static AudioScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AudioScope>();
    assert(scope != null, 'No AudioScope above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AudioScope oldWidget) => drone != oldWidget.drone;
}
