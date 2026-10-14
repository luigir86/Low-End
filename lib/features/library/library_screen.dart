import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/placeholder_section.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderSection(
      icon: Icons.library_music_outlined,
      description: AppLocalizations.of(context).libraryDescription,
    );
  }
}
