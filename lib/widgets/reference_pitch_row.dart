import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../audio/pitch.dart';
import '../l10n/app_localizations.dart';
import 'row_controls.dart';

/// The reference A, also in the settings, at hand on the tuner: a field with
/// its name on the border, − and + to step through the pitches, and a
/// pencil to choose one of the standard ones. The same pieces as the rows
/// of the metronome and the harmony.
class ReferencePitchRow extends StatelessWidget {
  const ReferencePitchRow({super.key});

  /// The standard pitches offered by the pencil: baroque, Verdi's, concert
  /// pitch and the orchestras'.
  static const standard = [415.0, 432.0, 440.0, 442.0];

  @override
  Widget build(BuildContext context) {
    final settings = AudioScope.of(context).settings;
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final at = referencePitches.indexOf(settings.a4);
        void step(int delta) =>
            settings.setReferencePitch(referencePitches[at + delta]);
        return Row(
          children: [
            Expanded(
              child: LabeledField(
                label: l10n.referencePitch,
                value: '${settings.a4.round()} Hz',
                onTap: () => _choose(context),
              ),
            ),
            const SizedBox(width: 6),
            RowChip(
              label: const Icon(Icons.remove, size: 24),
              tooltip: l10n.lowerPitch,
              onPressed: at > 0 ? () => step(-1) : null,
            ),
            const SizedBox(width: 4),
            RowChip(
              label: const Icon(Icons.add, size: 24),
              tooltip: l10n.higherPitch,
              onPressed: at < referencePitches.length - 1
                  ? () => step(1)
                  : null,
            ),
            RowIconButton(
              icon: Icons.edit_outlined,
              tooltip: l10n.choosePitch,
              onPressed: () => _choose(context),
            ),
          ],
        );
      },
    );
  }

  /// The four standard pitches, to choose from.
  Future<void> _choose(BuildContext context) async {
    final settings = AudioScope.of(context).settings;
    final l10n = AppLocalizations.of(context);
    final names = {
      415.0: l10n.pitchBaroque,
      432.0: l10n.pitchVerdi,
      440.0: l10n.pitchConcert,
      442.0: l10n.pitchOrchestras,
    };
    final picked = await showDialog<double>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.referencePitch),
        children: [
          for (final hz in standard)
            ListTile(
              title: Text('${hz.round()} Hz'),
              subtitle: Text(names[hz]!),
              selected: hz == settings.a4,
              trailing: hz == settings.a4 ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(hz),
            ),
        ],
      ),
    );
    if (picked != null) settings.setReferencePitch(picked);
  }
}
