import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/settings.dart';
import '../../../app/style.dart';
import '../../../widgets/row_controls.dart';
import '../../../app/theme.dart';
import '../../../audio/audio_scope.dart';
import '../../../audio/pitch.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/balance_slider.dart';
import '../../../widgets/dial.dart';
import '../../metronome/metronome_controller.dart';
import 'drone_controller.dart';
import 'harmony.dart';

/// The twelve notes in circle-of-fifths order, C at the top and clockwise:
/// each step is a fifth up, so the neighbours of a key are its closest
/// relatives.
const circleOfFifths = [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5];

/// The same twelve notes in semitones, C at the top: the order of the frets.
const chromaticCircle = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

/// The notes round the dial, clockwise from the top, as the player chose.
List<int> circleOrder(CircleLayout layout) => switch (layout) {
  CircleLayout.fifths => circleOfFifths,
  CircleLayout.chromatic => chromaticCircle,
};

/// The drone: the twelve notes as segments of the dial, round the circle of
/// fifths. Touching a segment plays that note and keeps it lit; touching
/// another switches to it; touching the lit one again stops it.
class DronePanel extends StatelessWidget {
  const DronePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AudioScope.of(context);
    final drone = scope.drone;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([drone, scope.settings]),
      builder: (context, _) {
        final names = scope.settings.noteNames(Localizations.localeOf(context));
        return DialLayout(
          dial: _FifthsDial(
            drone: drone,
            names: names,
            order: circleOrder(scope.settings.circleLayout),
          ),
          upper: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _VoicingSwitch(drone: drone),
              if (drone.audioFailed)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.audioUnavailable,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
          lower: _ChordMenu(drone: drone),
          footer: const BalanceSlider(),
        );
      },
    );
  }
}

class _FifthsDial extends StatelessWidget {
  const _FifthsDial({
    required this.drone,
    required this.names,
    required this.order,
  });

  final DroneController drone;
  final NoteNames names;
  final List<int> order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final playing = drone.isPlaying ? drone.rootPitchClass : null;
    // The rest of the chord, lit in a second colour while it sounds.
    final chord = drone.isPlaying ? drone.chordTones : const <int>{};
    // With a progression selected: the key's seven notes in front of the
    // rest.
    final tonic = drone.showsKey ? drone.note.pitchClass : null;
    final keyNotes = drone.keyNotes;
    // The Roman numerals of the progression, written small on the notes
    // they stand on, and not moving: you read II, then go to V.
    final degrees = drone.degreeLabels;
    // A note in the key is written as the key writes it (C♭ in G♭ major);
    // the others as chosen, and a hold on C♯ or F♯ writes them the other way.
    String nameOf(int pc, {bool flat = false}) {
      final letter = drone.keyLetterOf(pc);
      return letter != null
          ? spell(pc, letter, names)
          : Note(pc, drone.octave).name(names, flat: flat);
    }

    bool canRespell(int pc) =>
        DroneController.respellable.contains(pc) &&
        (drone.keyLetterOf(pc) == null || pc == tonic);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        // For a frame the dial can get almost no room (for instance while
        // the app rebuilds after a language change): draw nothing then.
        if (size.shortestSide < 120) return const SizedBox.shrink();
        final dial = DialGeometry(size);
        // A touch area per note, as wide as the ring is thick.
        final key = math.max(48.0, dial.ringWidth);
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FifthsPainter(
                  order: order,
                  playing: playing,
                  chord: chord,
                  keyNotes: keyNotes,
                  tonic: tonic,
                  colors: theme.colorScheme,
                  disc: LowEndColors.of(context).strobeBackground,
                ),
              ),
            ),
            for (var i = 0; i < 12; i++)
              Positioned.fromRect(
                rect: Rect.fromCenter(
                  center: dial.ringPoint(i * math.pi / 6),
                  width: key,
                  height: key,
                ),
                child: _NoteKey(
                  name: nameOf(order[i], flat: drone.spelledFlat(order[i])),
                  playing: playing == order[i],
                  inChord: chord.contains(order[i]),
                  degree: degrees[order[i]],
                  outOfKey: keyNotes.isNotEmpty && !keyNotes.contains(order[i]),
                  onTap: () => drone.tapNote(order[i]),
                  // C♯ or D♭, F♯ or G♭: the other name is written small
                  // under it, and holding the key switches to it, with the
                  // chords of its key.
                  respelling: canRespell(order[i])
                      ? Note(
                          order[i],
                          drone.octave,
                        ).name(names, flat: !drone.spelledFlat(order[i]))
                      : null,
                  onLongPress: () => drone.toggleSpelling(order[i]),
                ),
              ),
            // What is sounding, in the hub; large text shrinks to fit.
            // Touching the hub stops the drone, or plays the last note
            // again, like the metronome's ring.
            Center(
              child: SizedBox.square(
                dimension: dial.hub * 2,
                child: Semantics(
                  button: true,
                  label: drone.isPlaying
                      ? l10n.droneStop
                      : l10n.playSound(
                          spell(drone.note.pitchClass, drone.keyLetter, names),
                        ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: drone.toggle,
                      child: Center(
                        child: SizedBox.square(
                          dimension: dial.hub * math.sqrt2,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: dial.hub * math.sqrt2,
                              child: _DialCenter(drone: drone, names: names),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The ring of twelve segments: the root playing lit, the rest of a chord
/// in a second colour. The Roman numerals of a progression are written on
/// the keys themselves ([_NoteKey]), not painted here.
class _FifthsPainter extends CustomPainter {
  _FifthsPainter({
    required this.order,
    required this.playing,
    required this.chord,
    required this.keyNotes,
    required this.tonic,
    required this.colors,
    required this.disc,
  });

  final List<int> order;
  final int? playing;
  final Set<int> chord;

  /// The seven notes of the key, or empty when none is shown: the others
  /// recede into the disc (still there to be touched).
  final Set<int> keyNotes;
  final int? tonic;
  final ColorScheme colors;
  final Color disc;

  @override
  void paint(Canvas canvas, Size size) {
    final dial = DialGeometry(size);
    dial.paintBase(canvas, disc: disc, hub: colors.surface);
    const step = math.pi / 6;
    for (var i = 0; i < 12; i++) {
      final pc = order[i];
      final lit = playing == pc;
      final inChord = chord.contains(pc);
      final outOfKey = keyNotes.isNotEmpty && !keyNotes.contains(pc);
      final start = i * step - step / 2 + DialGeometry.gap / 2;
      const sweep = step - DialGeometry.gap;
      dial.paintSegment(
        canvas,
        startAngle: start,
        sweep: sweep,
        color: lit
            ? colors.primary
            : inChord
            ? colors.secondary
            : outOfKey
            ? Color.lerp(disc, colors.surface, 0.6)!
            : colors.outlineVariant,
        border: lit || inChord || outOfKey ? null : colors.outline,
      );
    }
  }

  @override
  bool shouldRepaint(_FifthsPainter old) =>
      !listEquals(old.order, order) ||
      old.playing != playing ||
      !setEquals(old.chord, chord) ||
      !setEquals(old.keyNotes, keyNotes) ||
      old.tonic != tonic ||
      old.colors != colors ||
      old.disc != disc;
}

/// The touch area and label of one segment; the segment itself is painted
/// by [_FifthsPainter].
class _NoteKey extends StatelessWidget {
  const _NoteKey({
    required this.name,
    required this.playing,
    required this.inChord,
    required this.degree,
    required this.outOfKey,
    required this.onTap,
    required this.respelling,
    required this.onLongPress,
  });

  final String name;
  final bool playing;

  /// A key is shown and the note is not in it.
  final bool outOfKey;

  /// Sounding as part of the chord built on the note playing.
  final bool inChord;
  final VoidCallback onTap;

  /// The Roman numeral of the progression on this note ("V"), or null.
  final String? degree;

  /// The other way to write the note (D♭ for C♯), or null if there is none.
  final String? respelling;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final respelling = this.respelling;
    return Semantics(
      button: true,
      selected: playing,
      // Says what a touch will do, not just the note name.
      label: playing ? l10n.stopSound(name) : l10n.playSound(name),
      onLongPressHint: respelling == null ? null : l10n.writeAs(respelling),
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          onLongPress: respelling == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onLongPress();
                },
          child: Center(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The function in the progression, small and still.
                    if (degree != null)
                      Text(
                        degree!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: playing
                              ? colors.onPrimary
                              : inChord
                              ? colors.onSecondary
                              : colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: playing
                            ? colors.onPrimary
                            : inChord
                            ? colors.onSecondary
                            : outOfKey
                            ? colors.onSurfaceVariant.withValues(alpha: 0.55)
                            : colors.onSurface,
                        // Bold for the root, so it stands out by more than
                        // colour alone.
                        fontWeight: playing ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    // The other way to write it, small: F♯ over G♭.
                    if (respelling != null)
                      Text(
                        respelling,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: playing
                              ? colors.onPrimary
                              : inChord
                              ? colors.onSecondary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What is sounding, in the middle of the dial: the root with its octave
/// small beside it, as on the tuner, then the chord, and in a progression
/// its degree in the key and how far through it is.
class _DialCenter extends StatelessWidget {
  const _DialCenter({required this.drone, required this.names});

  final DroneController drone;
  final NoteNames names;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (!drone.isPlaying) {
      return Text(l10n.droneHint, textAlign: TextAlign.center, style: muted);
    }
    final noteStyle = theme.textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.primary,
    );
    final root = Note(drone.rootPitchClass, drone.octave);
    // Spelled as in the key: D♯ in C♯ minor, G♭ in D♭.
    final rootName = spell(root.pitchClass, drone.rootLetter, names);
    final chord = drone.currentChord;
    final inProgression = drone.voicing == DroneVoicing.progression;
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: rootName),
                TextSpan(
                  text: '${root.octaveIn(names)}',
                  style: LowEndType.octave(noteStyle),
                ),
              ],
            ),
            style: noteStyle,
            textAlign: TextAlign.center,
          ),
          if (chord != null)
            Text(
              chordSymbol(l10n, chord, rootName),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          if (inProgression) ...[
            // The chord written out: Si Re Fa♯.
            if (chord != null)
              Text(
                _chordNotes(chord, drone.rootLetter, names).join(' '),
                textAlign: TextAlign.center,
                style: muted,
              ),
            const SizedBox(height: 6),
            _StepDots(
              count: drone.progression.steps.length,
              current: drone.step,
            ),
          ] else
            Text(
              l10n.frequencyHz(drone.frequency.toStringAsFixed(1)),
              style: muted,
            ),
        ],
      ),
    );
  }
}

/// One dot per chord of the progression, the one playing filled.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Twelve bars of blues need smaller dots to fit.
    final size = count > 6 ? 7.0 : 10.0;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              width: size,
              height: size,
              margin: EdgeInsets.symmetric(horizontal: size / 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == current ? colors.primary : null,
                border: Border.all(color: colors.outline, width: 1.2),
              ),
            ),
        ],
      ),
    );
  }
}

/// The name of a kind of chord, as listed in the chord menu.
String chordName(AppLocalizations l10n, ChordType chord) => switch (chord) {
  ChordType.major => l10n.chordMajor,
  ChordType.minor => l10n.chordMinor,
  ChordType.seventh => l10n.chordSeventh,
};

/// A chord on [note], as musicians write it: "A major", "La minore", "A7",
/// "Rem7", "Domaj7".
String chordSymbol(AppLocalizations l10n, DroneChord chord, String note) {
  if (chord.seventh) {
    return switch (chord.quality) {
      ChordQuality.major => '${note}maj7',
      ChordQuality.minor => '${note}m7',
      ChordQuality.dominant => l10n.droneChordSeventh(note),
      ChordQuality.halfDiminished => '${note}m7♭5',
    };
  }
  return switch (chord.quality) {
    ChordQuality.major || ChordQuality.dominant => l10n.droneChordMajor(note),
    ChordQuality.minor => l10n.droneChordMinor(note),
    ChordQuality.halfDiminished => l10n.droneChordDiminished(note),
  };
}

/// The name of a progression, as listed in its menu.
String progressionName(AppLocalizations l10n, Progression p) => switch (p) {
  Progression.twoFiveOne => 'II–V–I',
  Progression.minorTwoFiveOne => l10n.progressionMinorTwoFiveOne,
  Progression.oneFourFive => 'I–IV–V',
  Progression.oneSixFourFive => 'I–VI–IV–V',
  Progression.blues => l10n.progressionBlues,
};

/// The well-known song a progression is named after in the menu.
String progressionSong(Progression p) => switch (p) {
  Progression.twoFiveOne => 'Autumn Leaves',
  Progression.minorTwoFiveOne => 'Blue Bossa',
  Progression.oneFourFive => 'Twist and Shout',
  Progression.oneSixFourFive => 'Stand by Me',
  Progression.blues => 'Sweet Home Chicago',
};

/// The genre the progression belongs to.
String progressionGenre(AppLocalizations l10n, Progression p) => switch (p) {
  Progression.twoFiveOne => l10n.progressionGenreJazz,
  Progression.minorTwoFiveOne => l10n.progressionGenreMinorJazz,
  Progression.oneFourFive => l10n.progressionGenreRock,
  Progression.oneSixFourFive => l10n.progressionGenrePop,
  Progression.blues => l10n.progressionGenreBlues,
};

/// The line under the name in the menu: "Jazz standard, like Autumn Leaves".
String progressionNote(AppLocalizations l10n, Progression p) =>
    l10n.progressionLike(progressionGenre(l10n, p), progressionSong(p));

/// A progression in the menu: its name, and under it the genre and a song.
class _ProgressionEntry extends StatelessWidget {
  const _ProgressionEntry({required this.name, required this.note});

  final String name;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: theme.textTheme.titleMedium),
        Text(
          note,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Root, Chord or Progression, full width, as tall as the other sections'
/// first row.
class _VoicingSwitch extends StatelessWidget {
  const _VoicingSwitch({required this.drone});

  final DroneController drone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Long words ("Progressione") shrink rather than break mid-word.
    Widget label(String text) =>
        FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<DroneVoicing>(
        // A tick would take room from the labels; the filled segment
        // already shows the choice.
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(minimumSize: const Size(0, 64)),
        segments: [
          ButtonSegment(value: DroneVoicing.root, label: label(l10n.rootOnly)),
          ButtonSegment(
            value: DroneVoicing.chord,
            label: label(l10n.chordLabel),
          ),
          ButtonSegment(
            value: DroneVoicing.progression,
            label: label(l10n.progressionLabel),
          ),
        ],
        selected: {drone.voicing},
        onSelectionChanged: (s) => drone.setVoicing(s.first),
      ),
    );
  }
}

/// Which chord or which progression, and whether to add sevenths: hidden
/// for the root alone, its place kept so the rows line up with the other
/// sections. The button for the sound options is always there.
class _ChordMenu extends StatelessWidget {
  const _ChordMenu({required this.drone});

  final DroneController drone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progression = drone.voicing == DroneVoicing.progression;
    return Row(
      children: [
        Expanded(
          child: Visibility(
            visible: drone.voicing != DroneVoicing.root,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Row(
              children: [
                Expanded(
                  child: progression
                      ? DropdownMenu<Progression>(
                          // The text field keeps the name it was given: a new
                          // language needs a new menu.
                          key: ValueKey('progression-${l10n.localeName}'),
                          expandedInsets: EdgeInsets.zero,
                          // Also what screen readers announce with the choice.
                          label: Text(l10n.progressionLabel),
                          initialSelection: drone.progression,
                          dropdownMenuEntries: [
                            for (final p in Progression.values)
                              DropdownMenuEntry(
                                value: p,
                                // The field shows just the name once chosen
                                // (the song would not fit); the menu lists it
                                // with its note under it.
                                label: progressionName(l10n, p),
                                labelWidget: _ProgressionEntry(
                                  name: progressionName(l10n, p),
                                  note: progressionNote(l10n, p),
                                ),
                              ),
                          ],
                          onSelected: (p) {
                            if (p != null) drone.setProgression(p);
                          },
                        )
                      : DropdownMenu<ChordType>(
                          key: ValueKey('chord-${l10n.localeName}'),
                          expandedInsets: EdgeInsets.zero,
                          label: Text(l10n.chordLabel),
                          initialSelection: drone.chord,
                          dropdownMenuEntries: [
                            for (final chord in ChordType.values)
                              DropdownMenuEntry(
                                value: chord,
                                label: chordName(l10n, chord),
                              ),
                          ],
                          onSelected: (c) {
                            if (c != null) drone.setChord(c);
                          },
                        ),
                ),
                const SizedBox(width: 12),
                // Adds the seventh to every chord: maj7, m7, 7, m7♭5.
                Tooltip(
                  message: l10n.addSevenths,
                  child: FilterChip(
                    // The digit says it all; a tick would crowd it.
                    showCheckmark: false,
                    label: Text(
                      '+7',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: drone.sevenths
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    selected: drone.sevenths,
                    onSelected: drone.setSevenths,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        RowIconButton(
          icon: Icons.tune,
          tooltip: l10n.optionsLabel,
          onPressed: () => _showOptions(context, drone),
        ),
      ],
    );
  }
}

IconData _styleIcon(DroneStyle style) => switch (style) {
  // A long line for the chord held a bar, dots for the beats, a climb for
  // the arpeggio.
  DroneStyle.held => Icons.horizontal_rule,
  DroneStyle.beat => Icons.more_horiz,
  DroneStyle.arpeggio => Icons.trending_up,
};

String _styleName(AppLocalizations l10n, DroneStyle style) => switch (style) {
  DroneStyle.held => l10n.styleHeld,
  DroneStyle.beat => l10n.styleBeat,
  DroneStyle.arpeggio => l10n.styleArpeggio,
};

String _shapeName(AppLocalizations l10n, ChordShape shape) => switch (shape) {
  ChordShape.stacked => l10n.shapeStacked,
  ChordShape.close => l10n.shapeClose,
  ChordShape.rootless => l10n.shapeRootless,
};

/// The notes of [chord], root first, spelled by thirds from the letter of the
/// root: C E G, D♭ F A♭.
List<String> _chordNotes(DroneChord chord, int rootLetter, NoteNames names) => [
  spell(chord.root, rootLetter, names),
  for (final (i, s) in chord.quality.semitones(seventh: chord.seventh).indexed)
    spell((chord.root + s) % 12, (rootLetter + 2 * (i + 1)) % 7, names),
];

/// The sound options: how the chord or the progression is played (held, on
/// every beat or as an arpeggio, at the metronome's tempo), where its notes
/// sit on the keys, and the octave of the root.
Future<void> _showOptions(BuildContext context, DroneController drone) {
  final scope = AudioScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            drone,
            scope.metronome,
            scope.settings,
          ]),
          builder: (context, _) => _Options(
            drone: drone,
            metronome: scope.metronome,
            names: scope.settings.noteNames(Localizations.localeOf(context)),
          ),
        ),
      ),
    ),
  );
}

class _Options extends StatelessWidget {
  const _Options({
    required this.drone,
    required this.metronome,
    required this.names,
  });

  final DroneController drone;
  final MetronomeController metronome;
  final NoteNames names;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget heading(String text) => Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
    Widget label(String text) =>
        FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
    final chords = drone.voicing != DroneVoicing.root;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(l10n.octaveLabel),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
              segments: [
                // The root in each octave, as it is written: A2, A3, A4.
                for (final o in DroneController.octaves)
                  ButtonSegment(
                    value: o,
                    label: label(Note(drone.note.pitchClass, o).label(names)),
                  ),
              ],
              selected: {drone.octave},
              onSelectionChanged: (s) => drone.setOctave(s.first),
            ),
          ),
        ),
        if (drone.hasPiano) ...[
          if (chords) ...[
            heading(l10n.shapeLabel),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ChordShape>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  segments: [
                    for (final s in ChordShape.values)
                      ButtonSegment(
                        value: s,
                        label: label(_shapeName(l10n, s)),
                      ),
                  ],
                  selected: {drone.shape},
                  onSelectionChanged: (s) => drone.setShape(s.first),
                ),
              ),
            ),
          ],
          heading(l10n.styleLabel),
          RadioGroup<DroneStyle>(
            groupValue: drone.style,
            onChanged: (s) => drone.setStyle(s!),
            child: Column(
              children: [
                for (final style in DroneStyle.values)
                  RadioListTile<DroneStyle>(
                    value: style,
                    secondary: Icon(_styleIcon(style)),
                    title: Text(_styleName(l10n, style)),
                  ),
              ],
            ),
          ),
          // The piano keeps the metronome's time, wherever it is set.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              l10n.styleTempo(
                '${metronome.signature.beatUnit.symbol} = ${metronome.bpm}',
                metronome.signature.label,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ] else
          const SizedBox(height: 16),
      ],
    );
  }
}
