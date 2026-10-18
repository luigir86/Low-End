import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A short guide to the gestures that nothing on screen gives away, in three
/// brief pages, shown at the first launch and from the settings.
Future<void> showGuide(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const _Guide(),
);

class _Guide extends StatefulWidget {
  const _Guide();

  @override
  State<_Guide> createState() => _GuideState();
}

class _GuideState extends State<_Guide> {
  static const _pages = 3;
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget tip(IconData icon, String text) => ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(text),
    );
    Widget page(String title, List<Widget> tips) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        ...tips,
      ],
    );
    final pages = [
      page(l10n.guidePage1Title, [
        tip(Icons.touch_app_outlined, l10n.guideRing),
        tip(Icons.pin_outlined, l10n.guideTempo),
        tip(Icons.graphic_eq, l10n.guideDrone),
      ]),
      page(l10n.guidePage2Title, [
        tip(Icons.swipe, l10n.guideSwipe),
        tip(Icons.swipe_vertical, l10n.guideSwipeVertical),
        tip(Icons.lock_outline, l10n.guideLock),
      ]),
      page(l10n.guidePage3Title, [
        tip(Icons.mic_none, l10n.guideTuner),
        tip(Icons.straighten, l10n.guideCents),
        tip(Icons.volume_up_outlined, l10n.guideVolume),
      ]),
    ];
    final last = _page == _pages - 1;
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
            // Only the page shown is built: the sheet takes the height it
            // needs, and a swipe is not required to go on (the button does).
            Semantics(
              container: true,
              liveRegion: true,
              label: l10n.guidePageOf(_page + 1, _pages),
              child: pages[_page],
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages; i++)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page ? theme.colorScheme.primary : null,
                        border: Border.all(
                          color: theme.colorScheme.outline,
                          width: 1.2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: last
                  ? () => Navigator.of(context).pop()
                  : () => setState(() => _page++),
              child: Text(last ? l10n.guideDone : l10n.guideNext),
            ),
          ],
        ),
      ),
    );
  }
}
