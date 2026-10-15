import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../l10n/app_localizations.dart';

/// The metronome / drone balance, the same on both tabs: the metronome on
/// the left, the drone on the right, both at full level in the middle.
class BalanceSlider extends StatelessWidget {
  const BalanceSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AudioScope.of(context).settings;
    final l10n = AppLocalizations.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        String percent(double level) => '${(level * 100).round()}';
        final value = l10n.balanceValue(
          percent(settings.metronomeLevel),
          percent(settings.droneLevel),
        );
        return Row(
          children: [
            // The same icons as the tabs; the slider speaks for both.
            ExcludeSemantics(child: Icon(Icons.timer_outlined, color: muted)),
            Expanded(
              child: Semantics(
                label: l10n.balanceLabel,
                // One colour on both sides: a balance, not an amount that
                // fills from the left.
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Theme.of(context)
                        .colorScheme
                        .outlineVariant,
                  ),
                  child: Slider(
                    min: -1,
                    max: 1,
                    // Steps of a tenth, so the middle is easy to find again.
                    divisions: 20,
                    value: settings.balance,
                    onChanged: settings.setBalance,
                    semanticFormatterCallback: (_) => value,
                  ),
                ),
              ),
            ),
            ExcludeSemantics(child: Icon(Icons.graphic_eq, color: muted)),
          ],
        );
      },
    );
  }
}
