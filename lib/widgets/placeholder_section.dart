import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Temporary content for sections that are not built yet.
class PlaceholderSection extends StatelessWidget {
  const PlaceholderSection({
    super.key,
    required this.icon,
    required this.description,
  });

  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).comingSoon,
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
