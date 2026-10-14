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
    final drone = AudioScope.of(context).drone;
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return ListenableBuilder(
      listenable: drone,
      builder: (context, _) => Card(
        margin: const EdgeInsets.all(16),
        child: ListTile(
          leading: const Icon(Icons.graphic_eq),
          title: Text(l10n.droneNowPlaying(drone.note.label(language))),
          subtitle: Text(l10n.droneShortcutHint),
          trailing: IconButton.filledTonal(
            icon: Icon(drone.isPlaying ? Icons.stop_rounded : Icons.play_arrow),
            tooltip: drone.isPlaying ? l10n.stop : l10n.play,
            onPressed: drone.toggle,
          ),
        ),
      ),
    );
  }
}
