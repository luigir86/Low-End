import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme.dart';
import '../../audio/audio_scope.dart';
import '../../audio/pitch.dart';
import '../../l10n/app_localizations.dart';
import 'tuner_controller.dart';
import 'tunings.dart';

/// The tuner: listens to the microphone, names whatever note it hears (no
/// tuning to choose) and shows how far off it is on a round strobe, like
/// the Peterson tuners many bassists know, with the note in the middle.
class TunerPanel extends StatefulWidget {
  const TunerPanel({super.key});

  @override
  State<TunerPanel> createState() => _TunerPanelState();
}

class _TunerPanelState extends State<TunerPanel> {
  late TunerController _tuner;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Stop listening when the app goes to the background, and listen again
    // when it comes back with the tuner on screen.
    _lifecycle = AppLifecycleListener(
      onHide: () => _tuner.stop(),
      onShow: () {
        if (AudioScope.of(context).navigation.tunerVisible) _tuner.start();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tuner = AudioScope.of(context).tuner;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _tuner.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AudioScope.of(context).settings;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_tuner, settings]),
      builder: (context, _) {
        final names = settings.noteNames(Localizations.localeOf(context));
        final hz = _tuner.frequency;
        final reading = hz == null
            ? null
            : TunerReading.of(hz, tuning: _tuner.tuning, a4: settings.a4);
        final message = _statusMessage(l10n);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: SizedBox.square(
                      dimension: math.min(
                        constraints.biggest.shortestSide,
                        440,
                      ),
                      child: _StrobeDisc(
                        reading: reading,
                        listening: _tuner.isListening,
                        names: names,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (message != null)
                // Announced by screen readers, e.g. when the microphone is
                // denied.
                Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: _tuner.status == TunerStatus.idle
                        ? theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              // Listening is the normal state, so pausing stays discreet.
              TextButton.icon(
                onPressed: _tuner.toggle,
                icon: Icon(
                  _tuner.isListening ? Icons.pause : Icons.mic,
                  size: 20,
                ),
                label: Text(
                  _tuner.isListening ? l10n.stopListening : l10n.startListening,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _statusMessage(AppLocalizations l10n) => switch (_tuner.status) {
    TunerStatus.idle => l10n.tunerIdleHint,
    TunerStatus.permissionDenied => l10n.micPermissionDenied,
    TunerStatus.failed => l10n.micUnavailable,
    TunerStatus.starting || TunerStatus.listening => null,
  };
}

/// Green when in tune, ochre when close, red when far off: the shades live
/// in lib/app/theme.dart and keep at least 3:1 contrast (WCAG 1.4.3, 1.4.11).
Color _centsColor(ThemeData theme, double cents) {
  final colors = theme.extension<LowEndColors>()!;
  final off = cents.abs();
  if (off <= TunerReading.inTuneCents) return colors.inTune;
  if (off <= 15) return colors.close;
  return colors.off;
}

/// The round strobe, with the note and the verdict in its middle.
///
/// Two rings of segments turn anticlockwise when the note is flat and
/// clockwise when it is sharp, faster the further off it is, and stand still
/// when it is spot on. The inner ring turns twice as fast, so it shows even
/// a cent or two. With animations turned off in the phone settings, a still
/// marker on the rim shows the cents instead.
class _StrobeDisc extends StatefulWidget {
  const _StrobeDisc({
    required this.reading,
    required this.listening,
    required this.names,
  });

  final TunerReading? reading;
  final bool listening;
  final NoteNames names;

  @override
  State<_StrobeDisc> createState() => _StrobeDiscState();
}

class _StrobeDiscState extends State<_StrobeDisc>
    with SingleTickerProviderStateMixin {
  /// Segments per second for each cent off, on the outer ring.
  static const _speed = 0.5;

  /// Fastest turn, in segments per second: beyond this the eye loses track.
  static const _maxSpeed = 6.0;

  late final Ticker _ticker = createTicker(_tick);
  final _phase = ValueNotifier<double>(0);
  var _last = Duration.zero;

  bool get _animate => !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_StrobeDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Turns only while a note is heard, to save battery.
  void _sync() {
    final turning = widget.reading != null && _animate;
    if (turning && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!turning && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final seconds = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final cents = widget.reading?.cents ?? 0;
    final speed = (cents * _speed).clamp(-_maxSpeed, _maxSpeed);
    _phase.value = (_phase.value + speed * seconds) % 1024;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.reading;
    final segments = r == null
        ? theme.colorScheme.outlineVariant
        : _centsColor(theme, r.cents);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Moves on every frame: repaint only this part of the screen.
        RepaintBoundary(
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: _DiscPainter(
                phase: _phase,
                segments: segments,
                background: LowEndColors.of(context).strobeBackground,
                hub: theme.colorScheme.surface,
                // A still marker for players who turned animations off.
                stillCents: _animate ? null : r?.cents,
                scale: theme.colorScheme.outline,
              ),
            ),
          ),
        ),
        FractionallySizedBox(
          widthFactor: 0.5,
          heightFactor: 0.5,
          child: _NoteDisplay(
            reading: r,
            listening: widget.listening,
            names: widget.names,
          ),
        ),
      ],
    );
  }
}

class _DiscPainter extends CustomPainter {
  _DiscPainter({
    required this.phase,
    required this.segments,
    required this.background,
    required this.hub,
    required this.stillCents,
    required this.scale,
  }) : super(repaint: phase);

  final ValueNotifier<double> phase;
  final Color segments;
  final Color background;
  final Color hub;
  final double? stillCents;
  final Color scale;

  static const _count = 32;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final band = outer * 0.15;
    final gap = outer * 0.03;
    canvas.drawCircle(center, outer, Paint()..color = background);

    final paint = Paint()
      ..color = segments
      ..style = PaintingStyle.stroke
      ..strokeWidth = band;
    const step = 2 * math.pi / _count;
    for (var ring = 0; ring < 2; ring++) {
      final radius = outer - gap - band / 2 - ring * (band + gap);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final turn = stillCents == null ? phase.value * (ring + 1) * step : 0.0;
      for (var i = 0; i < _count; i++) {
        canvas.drawArc(rect, i * step + turn, step / 2, false, paint);
      }
    }

    // The hub, where the note is written.
    final hubRadius = outer - 2 * (band + gap) - gap;
    canvas.drawCircle(center, hubRadius, Paint()..color = hub);

    if (stillCents case final cents?) {
      // Ticks every 10 cents over the top of the rim, the marker on them.
      double angle(double c) => -math.pi / 2 + c / 50 * (math.pi * 3 / 4);
      final tick = Paint()
        ..color = scale
        ..strokeWidth = 2;
      for (var c = -50; c <= 50; c += 10) {
        final a = angle(c.toDouble());
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(
          center + dir * (hubRadius + gap),
          center + dir * (hubRadius + gap * 3),
          tick,
        );
      }
      final a = angle(cents.clamp(-50, 50));
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (hubRadius + gap),
        center + dir * (outer - gap),
        Paint()
          ..color = segments
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_DiscPainter old) =>
      old.segments != segments ||
      old.background != background ||
      old.hub != hub ||
      old.stillCents != stillCents ||
      old.scale != scale;
}

class _NoteDisplay extends StatelessWidget {
  const _NoteDisplay({
    required this.reading,
    required this.listening,
    required this.names,
  });

  final TunerReading? reading;
  final bool listening;
  final NoteNames names;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final r = reading;
    if (r == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            flex: 3,
            child: FittedBox(child: Text('–', style: _noteStyle(theme))),
          ),
          Flexible(
            child: FittedBox(
              child: Text(
                listening ? l10n.playAString : '',
                style: muted,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    final cents = r.cents.round();
    final direction = r.inTune
        ? l10n.inTune
        : (cents < 0 ? l10n.flat : l10n.sharp);
    final centsText = l10n.centsValue('${cents > 0 ? '+' : ''}$cents');
    final color = _centsColor(theme, r.cents);
    // Screen readers hear the note and whether it is flat, sharp or in tune,
    // only when that changes: reading every cent aloud would never stop.
    return Semantics(
      liveRegion: true,
      label: '${r.target.label(names)}, $direction',
      child: ExcludeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              flex: 3,
              child: FittedBox(
                child: _NoteName(note: r.target, names: names, color: color),
              ),
            ),
            Flexible(
              child: FittedBox(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A shape as well as a colour, for colour-blind players.
                    Icon(
                      r.inTune
                          ? Icons.check_circle
                          : (cents < 0
                                ? Icons.arrow_downward
                                : Icons.arrow_upward),
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.inTune ? direction : '$direction $centsText',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: FittedBox(
                child: Text(
                  l10n.frequencyHz(r.frequency.toStringAsFixed(1)),
                  style: muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle? _noteStyle(ThemeData theme) =>
    theme.textTheme.displayLarge?.copyWith(fontSize: 88, height: 1.05);

/// The note name, large, with its octave smaller beside it.
class _NoteName extends StatelessWidget {
  const _NoteName({
    required this.note,
    required this.names,
    required this.color,
  });

  final Note note;
  final NoteNames names;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = _noteStyle(Theme.of(context))
        ?.copyWith(color: color, fontWeight: FontWeight.w600);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: note.name(names)),
          TextSpan(
            text: '${note.octaveIn(names)}',
            style: TextStyle(fontSize: (style?.fontSize ?? 88) * 0.4),
          ),
        ],
      ),
      style: style,
      textAlign: TextAlign.center,
    );
  }
}
