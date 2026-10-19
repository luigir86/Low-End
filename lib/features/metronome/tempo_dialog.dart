import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/choice_menu.dart';
import '../../widgets/number_sheet.dart';
import 'metronome_controller.dart';

/// The tempi offered to pick from.
const tempoPresets = [60, 80, 100, 120, 140];

/// Asks for the tempo with the keyboard, with a few usual ones to pick, and
/// sets it on [metronome]. The same sheet as the reference A.
Future<void> showTempoDialog(
  BuildContext context,
  MetronomeController metronome,
) async {
  final l10n = AppLocalizations.of(context);
  final bpm = await showNumberSheet(
    context,
    title: l10n.setTempo,
    unit: 'BPM',
    current: metronome.bpm,
    min: MetronomeController.minBpm,
    max: metronome.maxTempo,
    shortcuts: [
      for (final b in tempoPresets) Choice(value: b, title: '$b BPM'),
    ],
  );
  if (bpm != null) metronome.setBpm(bpm);
}
