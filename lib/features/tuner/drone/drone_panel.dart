import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../audio/audio_scope.dart';
import '../../../audio/pitch.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/balance_slider.dart';
import '../../../widgets/dial.dart';
import 'drone_controller.dart';
import 'harmony.dart';

/// The twelve notes in circle-of-fifths order, C at the top and clockwise:
/// each step is a fifth up, so the neighbours of a key are its closest
/// relatives.
const circleOfFifths = [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5];

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
          dial: _FifthsDial(drone: drone, names: names),
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
  const _FifthsDial({required this.drone, required this.names});

  final DroneController drone;
  final NoteNames names;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final playing = drone.isPlaying ? drone.rootPitchClass : null;
    // The rest of the chord, lit in a second colour while it sounds.
    final chord = drone.isPlaying ? drone.chordTones : const <int>{};
    // In a progression: the key, always marked, and where it goes next.
    final inProgression =
        drone.isPlaying && drone.voicing == DroneVoicing.progression;
    final tonic = inProgression ? drone.note.pitchClass : null;
    final next = inProgression ? drone.nextChord?.root : null;
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
                  playing: playing,
                  chord: chord,
                  tonic: tonic,
                  next: next,
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
                  name: Note(
                    circleOfFifths[i],
                    DroneController.octave,
                  ).name(names),
                  playing: playing == circleOfFifths[i],
                  inChord: chord.contains(circleOfFifths[i]),
                  onTap: () => drone.tapNote(circleOfFifths[i]),
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
                      : l10n.playSound(drone.note.name(names)),
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
/// in a second colour; in a progression, a dot on the key and an outline
/// on the root that comes next.
class _FifthsPainter extends CustomPainter {
  _FifthsPainter({
    required this.playing,
    required this.chord,
    required this.tonic,
    required this.next,
    required this.colors,
    required this.disc,
  });

  final int? playing;
  final Set<int> chord;
  final int? tonic;
  final int? next;
  final ColorScheme colors;
  final Color disc;

  @override
  void paint(Canvas canvas, Size size) {
    final dial = DialGeometry(size);
    dial.paintBase(canvas, disc: disc, hub: colors.surface);
    const step = math.pi / 6;
    for (var i = 0; i < 12; i++) {
      final pc = circleOfFifths[i];
      final lit = playing == pc;
      final inChord = chord.contains(pc);
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
            : colors.outlineVariant,
      );
      if (next == pc && !lit) {
        dial.paintSegment(
          canvas,
          startAngle: start,
          sweep: sweep,
          color: colors.primary,
          stroke: 3,
        );
      }
      if (tonic == pc) {
        // A dot by the inner edge, in a colour that shows on the segment.
        canvas.drawCircle(
          dial.pointAt(i * step, dial.ringInner + dial.ringWidth * 0.14),
          dial.ringWidth * 0.06,
          Paint()
            ..color = lit
                ? colors.onPrimary
                : inChord
                ? colors.onSecondary
                : colors.primary,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FifthsPainter old) =>
      old.playing != playing ||
      !setEquals(old.chord, chord) ||
      old.tonic != tonic ||
      old.next != next ||
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
    required this.onTap,
  });

  final String name;
  final bool playing;

  /// Sounding as part of the chord built on the note playing.
  final bool inChord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: playing,
      // Says what a touch will do, not just the note name.
      label: playing ? l10n.stopSound(name) : l10n.playSound(name),
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: playing
                        ? colors.onPrimary
                        : inChord
                        ? colors.onSecondary
                        : colors.onSurface,
                    // Bold for the root, so it stands out by more than
                    // colour alone.
                    fontWeight: playing ? FontWeight.w800 : FontWeight.w500,
                  ),
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
    final root = Note(drone.rootPitchClass, DroneController.octave);
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
                TextSpan(text: root.name(names)),
                TextSpan(
                  text: '${root.octaveIn(names)}',
                  style: TextStyle(fontSize: (noteStyle?.fontSize ?? 45) * 0.4),
                ),
              ],
            ),
            style: noteStyle,
            textAlign: TextAlign.center,
          ),
          if (chord != null)
            Text(
              chordSymbol(l10n, chord, root.name(names)),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          if (inProgression) ...[
            Text(
              l10n.degreeOf(
                drone.progression.steps[drone.step].numeral,
                drone.note.name(names),
              ),
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
/// sections.
class _ChordMenu extends StatelessWidget {
  const _ChordMenu({required this.drone});

  final DroneController drone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progression = drone.voicing == DroneVoicing.progression;
    return Visibility(
      visible: drone.voicing != DroneVoicing.root,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Row(
        children: [
          Expanded(
            child: progression
                ? DropdownMenu<Progression>(
                    key: const ValueKey('progression'),
                    expandedInsets: EdgeInsets.zero,
                    // Also what screen readers announce with the choice.
                    label: Text(l10n.progressionLabel),
                    initialSelection: drone.progression,
                    dropdownMenuEntries: [
                      for (final p in Progression.values)
                        DropdownMenuEntry(
                          value: p,
                          label: progressionName(l10n, p),
                        ),
                    ],
                    onSelected: (p) {
                      if (p != null) drone.setProgression(p);
                    },
                  )
                : DropdownMenu<ChordType>(
                    key: const ValueKey('chord'),
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
                '7',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: drone.sevenths
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              selected: drone.sevenths,
              onSelected: drone.setSevenths,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
          ),
          if (drone.hasPiano) ...[
            const SizedBox(width: 8),
            _StyleMenu(drone: drone),
          ],
        ],
      ),
    );
  }
}

/// How the chord or the progression sounds: held, or on the piano, struck
/// on every beat or as an arpeggio, at the metronome's tempo.
class _StyleMenu extends StatelessWidget {
  const _StyleMenu({required this.drone});

  final DroneController drone;

  static IconData _icon(DroneStyle style) => switch (style) {
    DroneStyle.held => Icons.music_note,
    DroneStyle.beat => Icons.piano,
    DroneStyle.arpeggio => Icons.show_chart,
  };

  static String _name(AppLocalizations l10n, DroneStyle style) =>
      switch (style) {
        DroneStyle.held => l10n.styleHeld,
        DroneStyle.beat => l10n.styleBeat,
        DroneStyle.arpeggio => l10n.styleArpeggio,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AudioScope.of(context);
    final metronome = scope.metronome;
    return PopupMenuButton<DroneStyle>(
      tooltip: '${l10n.styleLabel}: ${_name(l10n, drone.style)}',
      initialValue: drone.style,
      onSelected: drone.setStyle,
      itemBuilder: (context) => [
        for (final style in DroneStyle.values)
          PopupMenuItem(
            value: style,
            child: Row(
              children: [
                Icon(_icon(style)),
                const SizedBox(width: 12),
                Text(_name(l10n, style)),
              ],
            ),
          ),
        // The piano keeps the metronome's time, wherever it is set.
        const PopupMenuDivider(),
        PopupMenuItem<DroneStyle>(
          enabled: false,
          child: Text(
            l10n.styleTempo(metronome.bpm, metronome.signature.label),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Icon(
          _icon(drone.style),
          size: 28,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
