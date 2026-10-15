import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../audio/pitch.dart';
import '../l10n/app_localizations.dart';
import 'about.dart';
import 'settings.dart';

/// Language, note names and reference A, plus the About box.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AudioScope.of(context).settings;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final example = const Note(
            9,
            4,
          ).label(settings.noteNames(Localizations.localeOf(context)));
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _Section(title: l10n.languageLabel),
              RadioGroup<String?>(
                groupValue: settings.languageCode,
                onChanged: settings.setLanguage,
                child: Column(
                  children: [
                    RadioListTile<String?>(
                      value: null,
                      title: Text(l10n.languageSystem),
                    ),
                    // Each language in its own name, so it can be found
                    // whatever the app is showing.
                    const RadioListTile<String?>(
                      value: 'en',
                      title: Text('English'),
                    ),
                    const RadioListTile<String?>(
                      value: 'it',
                      title: Text('Italiano'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _Section(title: l10n.noteNamesLabel),
              RadioGroup<NoteNaming>(
                groupValue: settings.naming,
                onChanged: (n) => settings.setNaming(n!),
                child: Column(
                  children: [
                    RadioListTile(
                      value: NoteNaming.auto,
                      title: Text(l10n.noteNamesAuto),
                    ),
                    RadioListTile(
                      value: NoteNaming.solfege,
                      title: Text(l10n.noteNamesSolfege),
                    ),
                    RadioListTile(
                      value: NoteNaming.letters,
                      title: Text(l10n.noteNamesLetters),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _Section(title: l10n.referencePitch),
              ListTile(
                title: Text(l10n.referencePitchHint(example)),
                // Screen readers would otherwise announce only "440 Hz".
                trailing: Semantics(
                  label: l10n.referencePitch,
                  child: DropdownButton<double>(
                    value: settings.a4,
                    items: [
                      for (final hz in referencePitches)
                        DropdownMenuItem(
                          value: hz,
                          child: Text('${hz.round()} Hz'),
                        ),
                    ],
                    onChanged: (hz) => settings.setReferencePitch(hz!),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(l10n.aboutTooltip),
                onTap: () => showLowEndAbout(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
