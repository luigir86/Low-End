import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/app_navigation.dart';
import '../../app/theme.dart';
import '../../audio/audio_scope.dart';
import '../../audio/mic_input.dart';
import '../../audio/pitch.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dial.dart';
import '../../widgets/reference_pitch_row.dart';
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
  late AppNavigation _navigation;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Stop listening when the app goes to the background, and listen again
    // when it comes back with the tuner on screen, unless the player paused
    // it. The callbacks use the controllers saved below: the context must
    // not be looked up from outside a build.
    _lifecycle = AppLifecycleListener(
      onHide: () => _tuner.stop(),
      onShow: () {
        if (_navigation.tunerVisible) _tuner.resume();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AudioScope.of(context);
    _tuner = scope.tuner;
    _navigation = scope.navigation;
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
        return DialLayout(
          compact: true,
          dial: _StrobeDisc(
            reading: reading,
            listening: _tuner.isListening,
            names: names,
          ),
          // Announced by screen readers, e.g. when the microphone is denied.
          upper: message == null
              ? const SizedBox.shrink()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    // A way out of a no: straight to the app's settings.
                    if (_tuner.status == TunerStatus.permissionDenied) ...[
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: openAppSettings,
                        icon: const Icon(Icons.settings_outlined),
                        label: Text(l10n.openSettings),
                      ),
                    ],
                  ],
                ),
          // As wide and tall as TAP and the chord menu, but only text:
          // listening is the normal state, so pausing stays discreet.
          footer: const ReferencePitchRow(),
          lower: TextButton.icon(
            onPressed: _tuner.toggle,
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(64)),
            icon: Icon(_tuner.isListening ? Icons.pause : Icons.mic, size: 20),
            label: Text(
              _tuner.isListening ? l10n.stopListening : l10n.startListening,
            ),
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
                // Waiting for a note: soft segments with a clear edge.
                edge: r == null ? theme.colorScheme.outline : null,
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
    required this.edge,
  }) : super(repaint: phase);

  final ValueNotifier<double> phase;
  final Color segments;
  final Color background;
  final Color hub;
  final double? stillCents;
  final Color scale;
  final Color? edge;

  static const _count = 32;

  @override
  void paint(Canvas canvas, Size size) {
    final dial = DialGeometry(size);
    dial.paintBase(canvas, disc: background, hub: hub);

    // Two bands of segments fill the ring, the inner one turning twice as
    // fast: the same ring the drone and the metronome use.
    const step = 2 * math.pi / _count;
    final split = dial.ringInner + dial.ringWidth / 2;
    final bandGap = dial.ringWidth * 0.06;
    for (var band = 0; band < 2; band++) {
      final turn = stillCents == null ? phase.value * (band + 1) * step : 0.0;
      for (var i = 0; i < _count; i++) {
        dial.paintSegment(
          canvas,
          startAngle: i * step + turn,
          sweep: step / 2,
          color: segments,
          inner: band == 0 ? split + bandGap / 2 : dial.ringInner,
          outer: band == 0 ? dial.ringOuter : split - bandGap / 2,
          border: edge,
        );
      }
    }

    // A fixed reference at 12 o'clock across both bands, with a pointer
    // above the hub: the segments stand still against it when in tune.
    final top = dial.center.dx;
    final y0 = dial.center.dy - dial.ringOuter;
    final y1 = dial.center.dy - dial.ringInner;
    canvas.drawLine(
      Offset(top, y0),
      Offset(top, y1),
      Paint()
        ..color = hub
        ..strokeWidth = 5,
    );
    canvas.drawLine(
      Offset(top, y0),
      Offset(top, y1),
      Paint()
        ..color = scale
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(top - dial.ringWidth * 0.14, y1)
        ..lineTo(top + dial.ringWidth * 0.14, y1)
        ..lineTo(top, y1 + dial.ringWidth * 0.26)
        ..close(),
      Paint()..color = scale,
    );

    if (stillCents case final cents?) {
      // Ticks every 10 cents over the top of the hub, the marker on them.
      final center = dial.center;
      double angle(double c) => -math.pi / 2 + c / 50 * (math.pi * 3 / 4);
      final tick = Paint()
        ..color = scale
        ..strokeWidth = 2;
      for (var c = -50; c <= 50; c += 10) {
        final a = angle(c.toDouble());
        final dir = Offset(math.cos(a), math.sin(a));
        // The tick for "in tune" is longer and thicker: told by shape.
        final zero = c == 0;
        canvas.drawLine(
          center + dir * (dial.hub * (zero ? 0.72 : 0.86)),
          center + dir * (dial.hub * (zero ? 1.0 : 0.96)),
          zero
              ? (Paint()
                  ..color = scale
                  ..strokeWidth = 4)
              : tick,
        );
      }
      final a = angle(cents.clamp(-50, 50));
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (dial.hub * 0.80),
        center + dir * dial.hub,
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
      old.scale != scale ||
      old.edge != edge;
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
    // A real minus sign: the hyphen is too short next to the plus.
    final centsText = l10n.centsValue(
      cents > 0 ? '+$cents' : (cents < 0 ? '−${-cents}' : '$cents'),
    );
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
              flex: 6,
              child: FittedBox(
                child: _NoteName(note: r.target, names: names, color: color),
              ),
            ),
            // The verdict, large enough to read from the music stand.
            Flexible(
              flex: 3,
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
                      size: 32,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      r.inTune ? direction : '$direction $centsText',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 2,
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
