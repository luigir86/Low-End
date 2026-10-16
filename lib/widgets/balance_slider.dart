import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../l10n/app_localizations.dart';

/// The metronome / drone balance, the same on both tabs: the metronome on
/// the left, the drone on the right, both at full level in the middle,
/// marked on the track.
class BalanceSlider extends StatelessWidget {
  const BalanceSlider({super.key});

  /// Room for an icon and its name under it, on each side.
  static const _sideWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    final settings = AudioScope.of(context).settings;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    Widget side(IconData icon, String name) => ExcludeSemantics(
      child: SizedBox(
        width: _sideWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: muted),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ),
          ],
        ),
      ),
    );
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        String percent(double level) => '${(level * 100).round()}';
        final value = l10n.balanceValue(
          percent(settings.metronomeLevel),
          percent(settings.droneLevel),
        );
        final row = Row(
          children: [
            // The same icons and names as the tabs; the slider speaks for
            // both.
            side(Icons.timer_outlined, l10n.metronomeTab),
            Expanded(
              child: Semantics(
                label: l10n.balanceLabel,
                // One colour on both sides: a balance, not an amount that
                // fills from the left.
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: theme.colorScheme.outlineVariant,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The middle, where both are at full level: under the
                      // thumb, so that it can be found again.
                      ExcludeSemantics(
                        child: IgnorePointer(
                          child: Container(
                            width: 2,
                            height: 16,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                      Slider(
                        min: -1,
                        max: 1,
                        // Steps of a tenth, so the middle is easy to find
                        // again.
                        divisions: 20,
                        value: settings.balance,
                        onChanged: settings.setBalance,
                        semanticFormatterCallback: (_) => value,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            side(Icons.graphic_eq, l10n.harmonyTab),
          ],
        );
        // The two icons and names say what it balances; the Semantics label
        // above speaks for screen readers.
        return row;
      },
    );
  }
}
