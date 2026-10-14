import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/placeholder_section.dart';

class TunerScreen extends StatelessWidget {
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderSection(
      icon: Icons.graphic_eq,
      description: AppLocalizations.of(context).tunerDescription,
    );
  }
}
