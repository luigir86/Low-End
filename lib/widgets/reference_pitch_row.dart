import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../audio/pitch.dart';
import '../l10n/app_localizations.dart';

/// The reference A, also in the settings, at hand on the tuner.
class ReferencePitchRow extends StatelessWidget {
  const ReferencePitchRow({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AudioScope.of(context).settings;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              l10n.referencePitch,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Screen readers would otherwise announce only "440 Hz".
          Semantics(
            label: l10n.referencePitch,
            child: DropdownButton<double>(
              value: settings.a4,
              items: [
                for (final hz in referencePitches)
                  DropdownMenuItem(value: hz, child: Text('${hz.round()} Hz')),
              ],
              onChanged: (hz) => settings.setReferencePitch(hz!),
            ),
          ),
        ],
      ),
    );
  }
}
