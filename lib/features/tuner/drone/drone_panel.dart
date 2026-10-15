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
        final key = (size * 0.16).clamp(48.0, 64.0);
        final radius = size / 2 - key / 2 - 4;
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
              child: SizedBox(
                width: radius * 1.3,
                child: _DialCenter(drone: drone, names: names),
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

/// What is sounding, in the middle of the dial.
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
    final what = drone.voicing == DroneVoicing.root
        ? l10n.rootOnly
        : chordName(l10n, drone.chord);
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            child: Text(
              drone.note.label(names),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Text(what, style: theme.textTheme.titleMedium),
          Text(
            l10n.frequencyHz(drone.frequency.toStringAsFixed(1)),
            style: muted,
          ),
        ],
      ),
    );
  }
}

String chordName(AppLocalizations l10n, ChordType chord) => switch (chord) {
  ChordType.major => l10n.chordMajor,
  ChordType.minor => l10n.chordMinor,
  ChordType.seventh => l10n.chordSeventh,
};

/// Root or chord, and which chord.
class _VoicingControls extends StatelessWidget {
  const _VoicingControls({required this.drone});

  final DroneController drone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chordMode = drone.voicing == DroneVoicing.chord;
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<DroneVoicing>(
            segments: [
              ButtonSegment(
                value: DroneVoicing.root,
                label: Text(l10n.rootOnly),
              ),
              ButtonSegment(
                value: DroneVoicing.chord,
                label: Text(l10n.chordLabel),
              ),
            ],
            selected: {drone.voicing},
            onSelectionChanged: (s) => drone.setVoicing(s.first),
          ),
        ),
        const SizedBox(width: 12),
        // Screen readers would otherwise announce only "Major".
        Semantics(
          label: l10n.chordLabel,
          child: DropdownButton<ChordType>(
            value: drone.chord,
            items: [
              for (final chord in ChordType.values)
                DropdownMenuItem(
                  value: chord,
                  child: Text(chordName(l10n, chord)),
                ),
            ],
            onChanged: chordMode ? (c) => drone.setChord(c!) : null,
          ),
        ),
      ],
    );
  }
}
