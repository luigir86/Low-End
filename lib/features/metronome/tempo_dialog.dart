import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'metronome_controller.dart';

/// Asks for the tempo with the keyboard, with a few usual ones to pick, and
/// sets it on [metronome].
Future<void> showTempoDialog(
  BuildContext context,
  MetronomeController metronome,
) => showDialog<void>(
  context: context,
  builder: (_) => _TempoDialog(metronome: metronome),
);

class _TempoDialog extends StatefulWidget {
  const _TempoDialog({required this.metronome});

  final MetronomeController metronome;

  @override
  State<_TempoDialog> createState() => _TempoDialogState();
}

class _TempoDialogState extends State<_TempoDialog> {
  /// The tempi offered to pick from.
  static const presets = [60, 80, 100, 120, 140];

  late final _text = TextEditingController(text: '${widget.metronome.bpm}');

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

  void _set(int? bpm) {
    if (bpm != null) widget.metronome.setBpm(bpm);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final max = widget.metronome.maxTempo;
    return AlertDialog(
      title: Text(l10n.setTempo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _text,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(
              suffixText: 'BPM',
              helperText: '${MetronomeController.minBpm}–$max',
            ),
            onSubmitted: (text) => _set(int.tryParse(text)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final bpm in presets)
                ActionChip(label: Text('$bpm'), onPressed: () => _set(bpm)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => _set(int.tryParse(_text.text)),
          child: Text(material.okButtonLabel),
        ),
      ],
    );
  }
}
