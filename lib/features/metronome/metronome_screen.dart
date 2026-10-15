import 'package:flutter/material.dart';

import '../../audio/audio_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/placeholder_section.dart';

class MetronomeScreen extends StatelessWidget {
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: PlaceholderSection(
            icon: Icons.timer_outlined,
            description: l10n.metronomeDescription,
          ),
        ),
        const _DroneShortcut(),
      ],
    );
  }
}

/// Turns the drone on or off without leaving the metronome.
class _DroneShortcut extends StatelessWidget {
  const _DroneShortcut();

  @override
  Widget build(BuildContext context) {
    final scope = AudioScope.of(context);
    final drone = scope.drone;
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([drone, scope.settings]),
      builder: (context, _) {
        final names = scope.settings.noteNames(Localizations.localeOf(context));
        final label = l10n.droneNowPlaying(drone.note.label(names));
        return Card(
          margin: const EdgeInsets.all(16),
          child: ListTile(
            leading: const Icon(Icons.graphic_eq),
            title: Text(label),
            subtitle: Text(l10n.droneShortcutHint),
            trailing: IconButton.filledTonal(
              icon: Icon(
                drone.isPlaying ? Icons.stop_rounded : Icons.play_arrow,
              ),
              // Says what it plays, not just "Play".
              tooltip: drone.isPlaying
                  ? l10n.stopSound(label)
                  : l10n.playSound(label),
              onPressed: drone.toggle,
            ),
          ),
        );
      },
    );
  }
}
