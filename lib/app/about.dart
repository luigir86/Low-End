import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

const sourceCodeUrl = 'https://github.com/luigir86/Low-End';

/// The About dialog: what the app does, its licence, and the licences of the
/// open-source packages it is built with (the MIT and BSD licences ask for
/// their notices to ship with the app).
void showLowEndAbout(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  showAboutDialog(
    context: context,
    applicationName: l10n.appTitle,
    applicationIcon: Icon(
      Icons.graphic_eq,
      size: 40,
      color: Theme.of(context).colorScheme.primary,
    ),
    applicationLegalese: l10n.aboutLegalese,
    children: [
      const SizedBox(height: 16),
      Text(l10n.aboutDescription),
      const SizedBox(height: 8),
      SelectableText(l10n.aboutSource(sourceCodeUrl)),
    ],
  );
}
