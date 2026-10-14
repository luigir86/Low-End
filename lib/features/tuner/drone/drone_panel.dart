import 'package:flutter/material.dart';

import '../../../audio/audio_scope.dart';
import '../../../audio/pitch.dart';
import '../../../l10n/app_localizations.dart';
import 'drone_controller.dart';

/// Controls for the drone: note, octave, added intervals, reference pitch and
/// volume, plus the big play/stop button.
class DronePanel extends StatelessWidget {
  const DronePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final drone = AudioScope.of(context).drone;
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: drone,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(
              drone.note.label(language),
              style: theme.textTheme.displayMedium,
            ),
          ),
          Center(
            child: Text(
              l10n.frequencyHz(drone.frequency.toStringAsFixed(1)),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: drone.toggle,
              icon: Icon(
                drone.isPlaying ? Icons.stop_rounded : Icons.play_arrow,
              ),
              label: Text(drone.isPlaying ? l10n.stop : l10n.play),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 56),
                textStyle: theme.textTheme.titleMedium,
              ),
            ),
          ),
          if (drone.audioFailed) ...[
            const SizedBox(height: 8),
            Text(
              l10n.audioUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          Text(l10n.noteLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _NotePicker(drone: drone, language: language),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.octaveLabel,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton.outlined(
                icon: const Icon(Icons.remove),
                onPressed: drone.note.octave > DroneController.minOctave
                    ? () => drone.setOctave(drone.note.octave - 1)
                    : null,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${drone.note.octave}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton.outlined(
                icon: const Icon(Icons.add),
                onPressed: drone.note.octave < DroneController.maxOctave
                    ? () => drone.setOctave(drone.note.octave + 1)
                    : null,
              ),
            ],
          ),
          if (drone.isBelowSpeakerRange)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.headphones,
                    size: 18,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.lowNoteWarning,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.addFifth),
            value: drone.addFifth,
            onChanged: drone.setAddFifth,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.addOctave),
            value: drone.addOctave,
            onChanged: drone.setAddOctave,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.referencePitch,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              DropdownButton<double>(
                value: drone.a4,
                items: [
                  for (final hz in referencePitches)
                    DropdownMenuItem(
                      value: hz,
                      child: Text('${hz.round()} Hz'),
                    ),
                ],
                onChanged: (hz) => drone.setReferencePitch(hz!),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.volume_down),
              Expanded(
                child: Slider(
                  value: drone.volume,
                  onChanged: drone.setVolume,
                  semanticFormatterCallback: (v) =>
                      '${l10n.volumeLabel} ${(v * 100).round()}%',
                ),
              ),
              const Icon(Icons.volume_up),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotePicker extends StatelessWidget {
  const _NotePicker({required this.drone, required this.language});

  final DroneController drone;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var pc = 0; pc < 12; pc++)
          ChoiceChip(
            label: SizedBox(
              width: 40,
              child: Text(
                Note(pc, drone.note.octave).name(language),
                textAlign: TextAlign.center,
              ),
            ),
            selected: drone.note.pitchClass == pc,
            showCheckmark: false,
            onSelected: (_) => drone.setPitchClass(pc),
          ),
      ],
    );
  }
}
