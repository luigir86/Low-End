import 'package:flutter/material.dart';

import '../../app/app_navigation.dart';
import '../../audio/audio_scope.dart';
import '../../l10n/app_localizations.dart';
import 'drone/drone_panel.dart';
import 'tuner_panel.dart';

/// Tuner section, with the drone as its second mode.
class TunerScreen extends StatelessWidget {
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final navigation = AudioScope.of(context).navigation;
    return ListenableBuilder(
      listenable: navigation,
      builder: (context, _) => Column(
        children: [
          Expanded(
            child: switch (navigation.tunerMode) {
              AppSection.drone => const DronePanel(),
              _ => const TunerPanel(),
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            // Next to the navigation bar, within reach of the thumb.
            child: SegmentedButton<AppSection>(
              expandedInsets: EdgeInsets.zero,
              segments: [
                ButtonSegment(
                  value: AppSection.tuner,
                  label: Text(l10n.tuneMode),
                  icon: const Icon(Icons.tune),
                ),
                ButtonSegment(
                  value: AppSection.drone,
                  label: Text(l10n.droneMode),
                  icon: const Icon(Icons.graphic_eq),
                ),
              ],
              selected: {navigation.tunerMode},
              onSelectionChanged: (s) => navigation.open(s.first),
            ),
          ),
        ],
      ),
    );
  }
}
