import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A short guide to the gestures that nothing on screen gives away, shown at
/// the first launch and from the settings.
Future<void> showGuide(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const _Guide(),
);

class _Guide extends StatelessWidget {
  const _Guide();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget tip(IconData icon, String text) => ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(text),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.guideTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            tip(Icons.touch_app_outlined, l10n.guideRing),
            tip(Icons.pin_outlined, l10n.guideTempo),
            tip(Icons.swipe, l10n.guideSwipe),
            tip(Icons.ads_click, l10n.guideHold),
            tip(Icons.graphic_eq, l10n.guideDrone),
            tip(Icons.mic_none, l10n.guideTuner),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.guideDone),
            ),
          ],
        ),
      ),
    );
  }
}
