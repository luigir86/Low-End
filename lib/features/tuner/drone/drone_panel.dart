import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../audio/audio_scope.dart';
import '../../../audio/pitch.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/dial.dart';
import 'drone_controller.dart';

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
    final playing = drone.isPlaying ? drone.note.pitchClass : null;
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
                  onTap: () => drone.tapNote(circleOfFifths[i]),
                ),
              ),
            // What is sounding, in the hub; large text shrinks to fit.
            Center(
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
          ],
        );
      },
    );
  }
}

/// The ring of twelve segments, the one playing lit.
class _FifthsPainter extends CustomPainter {
  _FifthsPainter({
    required this.playing,
    required this.colors,
    required this.disc,
  });

  final int? playing;
  final ColorScheme colors;
  final Color disc;

  @override
  void paint(Canvas canvas, Size size) {
    final dial = DialGeometry(size);
    dial.paintBase(canvas, disc: disc, hub: colors.surface);
    const step = math.pi / 6;
    for (var i = 0; i < 12; i++) {
      dial.paintSegment(
        canvas,
        startAngle: i * step - step / 2 + DialGeometry.gap / 2,
        sweep: step - DialGeometry.gap,
        color: playing == circleOfFifths[i]
            ? colors.primary
            : colors.outlineVariant,
      );
    }
  }

  @override
  bool shouldRepaint(_FifthsPainter old) =>
      old.playing != playing || old.colors != colors || old.disc != disc;
}

/// The touch area and label of one segment; the segment itself is painted
/// by [_FifthsPainter].
class _NoteKey extends StatelessWidget {
  const _NoteKey({
    required this.name,
    required this.playing,
    required this.onTap,
  });

  final String name;
  final bool playing;
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
                    color: playing ? colors.onPrimary : colors.onSurface,
                    fontWeight: playing ? FontWeight.w700 : FontWeight.w500,
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

/// What is sounding, in the middle of the dial: the note with its octave
/// small beside it, as on the tuner, then the chord if one is played.
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
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: drone.note.name(names)),
                TextSpan(
                  text: '${drone.note.octaveIn(names)}',
                  style: TextStyle(fontSize: (noteStyle?.fontSize ?? 45) * 0.4),
                ),
              ],
            ),
            style: noteStyle,
            textAlign: TextAlign.center,
          ),
          if (drone.voicing == DroneVoicing.chord)
            Text(
              chordSymbol(l10n, drone.chord, drone.note.name(names)),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          Text(
            l10n.frequencyHz(drone.frequency.toStringAsFixed(1)),
            style: muted,
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

/// A chord on [note], as musicians write it: "A major", "La minore", "A7".
String chordSymbol(AppLocalizations l10n, ChordType chord, String note) =>
    switch (chord) {
      ChordType.major => l10n.droneChordMajor(note),
      ChordType.minor => l10n.droneChordMinor(note),
      ChordType.seventh => l10n.droneChordSeventh(note),
    };

/// Root or Chord, full width, as tall as the other sections' first row.
class _VoicingSwitch extends StatelessWidget {
  const _VoicingSwitch({required this.drone});

  final DroneController drone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<DroneVoicing>(
        // A tick would take room from the labels; the filled segment
        // already shows the choice.
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(minimumSize: const Size(0, 64)),
        segments: [
          ButtonSegment(value: DroneVoicing.root, label: Text(l10n.rootOnly)),
          ButtonSegment(
            value: DroneVoicing.chord,
            label: Text(l10n.chordLabel),
          ),
        ],
        selected: {drone.voicing},
        onSelectionChanged: (s) => drone.setVoicing(s.first),
      ),
    );
  }
}

/// Which chord: shown only when a chord plays, its place kept otherwise so
/// the rows line up with the other sections.
class _ChordMenu extends StatelessWidget {
  const _ChordMenu({required this.drone});

  final DroneController drone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Visibility(
      visible: drone.voicing == DroneVoicing.chord,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: DropdownMenu<ChordType>(
        expandedInsets: EdgeInsets.zero,
        // Also what screen readers announce with the choice.
        label: Text(l10n.chordLabel),
        initialSelection: drone.chord,
        dropdownMenuEntries: [
          for (final chord in ChordType.values)
            DropdownMenuEntry(value: chord, label: chordName(l10n, chord)),
        ],
        onSelected: (c) {
          if (c != null) drone.setChord(c);
        },
      ),
    );
  }
}
