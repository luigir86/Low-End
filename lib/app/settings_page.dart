import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../audio/pitch.dart';
import '../l10n/app_localizations.dart';
import '../widgets/choice_menu.dart';
import '../widgets/row_controls.dart';
import 'about.dart';
import 'guide.dart';
import 'settings.dart';

/// Language, theme, screen, note names and reference A, plus the About box.
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
          final names = settings.noteNames(Localizations.localeOf(context));
          final example = const Note(
            9,
            4,
          ).label(names, numbering: settings.octaveNumbering);
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
              SwitchListTile(
                value: settings.keepScreenOn,
                onChanged: settings.setKeepScreenOn,
                title: Text(l10n.keepScreenOnTitle),
                subtitle: Text(l10n.keepScreenOnSubtitle),
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
                // The field announces its name too, not only "440 Hz".
                trailing: _MenuField<double>(
                  key: const Key('referencePitchMenu'),
                  label: l10n.referencePitch,
                  selected: settings.a4,
                  choices: [
                    for (final hz in referencePitches)
                      Choice(value: hz, title: '${hz.round()} Hz'),
                  ],
                  onSelected: settings.setReferencePitch,
                ),
              ),
              const Divider(),
              _Section(title: l10n.circleLayoutLabel),
              RadioGroup<CircleLayout>(
                groupValue: settings.circleLayout,
                onChanged: (c) => settings.setCircleLayout(c!),
                child: Column(
                  children: [
                    RadioListTile(
                      value: CircleLayout.fifths,
                      title: Text(l10n.circleLayoutFifths),
                    ),
                    RadioListTile(
                      value: CircleLayout.chromatic,
                      title: Text(l10n.circleLayoutChromatic),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _Section(title: l10n.octaveNumberingLabel),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  l10n.octaveNumberingHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              RadioGroup<OctaveNumbering>(
                groupValue: settings.octaveNumbering,
                onChanged: (n) => settings.setOctaveNumbering(n!),
                child: Column(
                  children: [
                    RadioListTile(
                      value: OctaveNumbering.scientific,
                      title: Text(l10n.octaveScientific),
                      subtitle: Text(
                        l10n.octaveExamples(
                          const Note(
                            9,
                            4,
                          ).label(names, numbering: OctaveNumbering.scientific),
                          const Note(
                            4,
                            1,
                          ).label(names, numbering: OctaveNumbering.scientific),
                        ),
                      ),
                    ),
                    RadioListTile(
                      value: OctaveNumbering.italian,
                      title: Text(l10n.octaveItalian),
                      subtitle: Text(
                        l10n.octaveExamples(
                          const Note(
                            9,
                            4,
                          ).label(names, numbering: OctaveNumbering.italian),
                          const Note(
                            4,
                            1,
                          ).label(names, numbering: OctaveNumbering.italian),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              SwitchListTile(
                value: settings.gesturesLocked,
                onChanged: settings.setGesturesLocked,
                title: Text(l10n.gesturesLockedTitle),
                subtitle: Text(l10n.gesturesLockedSubtitle),
              ),
              ListTile(
                title: Text(l10n.inTuneZoneTitle),
                subtitle: Text(l10n.inTuneZoneSubtitle),
                trailing: _MenuField<double>(
                  key: const Key('inTuneZoneMenu'),
                  label: l10n.inTuneZoneTitle,
                  selected: settings.inTuneCents,
                  choices: [
                    for (final cents in AppSettings.inTuneChoices)
                      Choice(
                        value: cents,
                        title: l10n.centsValue('±${cents.round()}'),
                      ),
                  ],
                  onSelected: settings.setInTuneCents,
                ),
              ),
              ListTile(
                title: Text(l10n.transpositionTitle),
                subtitle: Text(l10n.transpositionSubtitle),
              ),
              // The key the instrument's written C sounds; C is concert
              // pitch.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Semantics(
                  label: l10n.transpositionTitle,
                  container: true,
                  child: SegmentedButton<Transposition>(
                    key: const Key('transposition'),
                    showSelectedIcon: false,
                    segments: [
                      for (final t in Transposition.values)
                        ButtonSegment(
                          value: t,
                          label: Text(Note(t.key, 4).name(names)),
                          tooltip: t == Transposition.c
                              ? l10n.transpositionConcert
                              : null,
                        ),
                    ],
                    selected: {settings.transposition},
                    onSelectionChanged: (s) =>
                        settings.setTransposition(s.first),
                  ),
                ),
              ),
              const Divider(),
              _Section(title: l10n.thanksTitle),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(l10n.thanksText),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  // A link out, said by its icon and its words.
                  child: OutlinedButton.icon(
                    key: const Key('orchestraLink'),
                    onPressed: () => openLink(orchestraUrl),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(l10n.thanksInstagram),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(l10n.guideTitle),
                onTap: () => showGuide(context),
              ),
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

/// A setting chosen from a list: the field of the rows under the dials, its
/// name left to the line it ends, opening the menu of the whole app.
class _MenuField<T> extends StatelessWidget {
  const _MenuField({
    super.key,
    required this.label,
    required this.selected,
    required this.choices,
    required this.onSelected,
  });

  final String label;
  final T selected;
  final List<Choice<T>> choices;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 136,
    child: LabeledField(
      label: label,
      showLabel: false,
      value: choices.firstWhere((c) => c.value == selected).title,
      onTap: () async {
        final picked = await showChoiceMenu(
          anchor: context,
          selected: selected,
          choices: choices,
        );
        if (picked != null) onSelected(picked);
      },
    ),
  );
}
