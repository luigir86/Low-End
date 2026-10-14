import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/placeholder_section.dart';

class MetronomeScreen extends StatelessWidget {
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderSection(
      icon: Icons.timer_outlined,
      description: AppLocalizations.of(context).metronomeDescription,
    );
  }
}
