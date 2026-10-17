import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_scope.dart';
import '../audio/pitch.dart';
import '../l10n/app_localizations.dart';
import 'row_controls.dart';

/// The reference A, also in the settings, at hand on the tuner: a field with
/// its name on the border, − and + to step through the hertz from 415 to
/// 445, and a pencil to type a pitch or choose one of the standard ones. The
/// same pieces as the rows of the metronome and the harmony.
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
        final a4 = settings.a4;
        void step(double delta) => settings.setReferencePitch(a4 + delta);
        return Row(
          children: [
            Expanded(
              child: LabeledField(
                label: l10n.referencePitch,
                value: '${a4.round()} Hz',
                onTap: () => _choose(context),
              ),
            ),
            const SizedBox(width: 6),
            RowChip(
              label: const Icon(Icons.remove, size: 24),
              tooltip: l10n.lowerPitch,
              onPressed: a4 > minReferencePitch ? () => step(-1) : null,
            ),
            const SizedBox(width: 4),
            RowChip(
              label: const Icon(Icons.add, size: 24),
              tooltip: l10n.higherPitch,
              onPressed: a4 < maxReferencePitch ? () => step(1) : null,
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

  /// A pitch typed in, with the four standard ones to choose from.
  Future<void> _choose(BuildContext context) async {
    final settings = AudioScope.of(context).settings;
    final picked = await showDialog<double>(
      context: context,
      builder: (context) => _PitchDialog(current: settings.a4),
    );
    if (picked != null) settings.setReferencePitch(picked);
  }
}

class _PitchDialog extends StatefulWidget {
  const _PitchDialog({required this.current});

  final double current;

  @override
  State<_PitchDialog> createState() => _PitchDialogState();
}

class _PitchDialogState extends State<_PitchDialog> {
  late final _text = TextEditingController(text: '${widget.current.round()}');

  @override
  void initState() {
    super.initState();
    // Typing replaces the number: it is all selected.
    _text.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _text.text.length,
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Closes with the typed pitch, kept within the range; with nothing
  /// typed, nothing changes.
  void _submit() {
    final hz = int.tryParse(_text.text);
    Navigator.of(context).pop(
      hz
          ?.clamp(minReferencePitch.toInt(), maxReferencePitch.toInt())
          .toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final names = {
      415.0: l10n.pitchBaroque,
      432.0: l10n.pitchVerdi,
      440.0: l10n.pitchConcert,
      442.0: l10n.pitchOrchestras,
    };
    return AlertDialog(
      title: Text(l10n.referencePitch),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('pitchField'),
            controller: _text,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(
              suffixText: 'Hz',
              helperText:
                  '${minReferencePitch.round()}–${maxReferencePitch.round()}',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          for (final hz in ReferencePitchRow.standard)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${hz.round()} Hz'),
              subtitle: Text(names[hz]!),
              selected: hz == widget.current,
              trailing: hz == widget.current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(hz),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(material.okButtonLabel)),
      ],
    );
  }
}
