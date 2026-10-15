import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../audio/audio_scope.dart';
import '../../../audio/pitch.dart';
import '../../../l10n/app_localizations.dart';
import 'drone_controller.dart';

/// The drone: twelve note keys round a dial, like a clock with C at the
/// top. Touching a key plays that note and keeps it lit; touching another
/// switches to it; touching the lit one again stops it.
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
        return LayoutBuilder(
          builder: (context, constraints) {
            // Leave room below for the voicing controls.
            final dial = math.min(
              math.min(constraints.maxWidth - 32, constraints.maxHeight - 150),
              420.0,
            );
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Centred in the height when it fits; it scrolls when it does
                // not (large text, landscape).
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - 16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: SizedBox.square(
                          dimension: math.max(dial, 260),
                          child: _NoteDial(drone: drone, names: names),
                        ),
                      ),
                      if (drone.audioFailed)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            l10n.audioUnavailable,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _VoicingControls(drone: drone),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _NoteDial extends StatelessWidget {
  const _NoteDial({required this.drone, required this.names});

  final DroneController drone;
  final NoteNames names;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        // For a frame the dial can get almost no room (for instance while
        // the app rebuilds after a language change): draw nothing then.
        if (size < 200) return const SizedBox.shrink();
        final key = (size * 0.16).clamp(48.0, 64.0);
        final radius = math.max(0.0, size / 2 - key / 2 - 4);
        // The largest square inside the ring of keys.
        final inner = math.max(0.0, radius - key / 2 - 4) * math.sqrt2;
        final center = size / 2;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DialPainter(
                  track: theme.colorScheme.outlineVariant,
                  radius: radius,
                ),
              ),
            ),
            for (var pc = 0; pc < 12; pc++)
              Positioned(
                left: center + radius * math.sin(pc * math.pi / 6) - key / 2,
                top: center - radius * math.cos(pc * math.pi / 6) - key / 2,
                width: key,
                height: key,
                child: _NoteKey(
                  name: Note(pc, DroneController.octave).name(names),
                  playing: drone.isPlaying && drone.note.pitchClass == pc,
                  onTap: () => drone.tapNote(pc),
                ),
              ),
            Center(
              // Large text shrinks to fit inside the keys rather than spill
              // over them.
              child: SizedBox.square(
                dimension: inner,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: inner,
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

class _DialPainter extends CustomPainter {
  _DialPainter({required this.track, required this.radius});

  final Color track;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.track != track || old.radius != radius;
}

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
        shape: CircleBorder(
          side: playing
              ? BorderSide.none
              : BorderSide(color: colors.outline, width: 1.5),
        ),
        color: playing ? colors.primary : colors.surfaceContainerLow,
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

/// Root or chord and, for a chord, which one. Stacked rather than side by
/// side, so long labels ("Fondamentale") keep the whole width with large
/// text, and the chord menu never opens over the switch.
class _VoicingControls extends StatelessWidget {
  const _VoicingControls({required this.drone});

  final DroneController drone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chordMode = drone.voicing == DroneVoicing.chord;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<DroneVoicing>(
          // A tick would take room from the labels; the filled segment
          // already shows the choice.
          showSelectedIcon: false,
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
        // The chord menu only when a chord plays.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: chordMode
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DropdownMenu<ChordType>(
                    expandedInsets: EdgeInsets.zero,
                    // Also what screen readers announce with the choice.
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
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
