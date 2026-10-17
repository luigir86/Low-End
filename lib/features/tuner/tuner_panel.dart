import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/app_navigation.dart';
import '../../app/settings.dart';
import '../../app/style.dart';
import '../../app/theme.dart';
import '../../audio/audio_scope.dart';
import '../../audio/mic_input.dart';
import '../../audio/pitch.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dial.dart';
import '../../widgets/reference_pitch_row.dart';
import 'tuner_controller.dart';
import 'tuner_reading.dart';
import 'tuner_tuning.dart';

/// The tuner: listens to the microphone, names whatever note it hears (no
/// tuning to choose) and shows how far off it is on a round strobe, like
/// the Peterson tuners, with the note in the middle.
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
            : TunerReading.of(
                hz,
                a4: settings.a4,
                tolerance: settings.inTuneCents,
                tuning: settings.tuning,
              );
        final message = _statusMessage(l10n);
        return DialLayout(
          dial: _StrobeDisc(
            reading: reading,
            held: _tuner.held,
            tolerance: settings.inTuneCents,
            listening: _tuner.isListening,
            names: names,
            numbering: settings.octaveNumbering,
            onToggle: _tuner.toggle,
          ),
          // Announced by screen readers, e.g. when the microphone is denied.
          upper: message == null
              ? _CentsBar(
                  reading: reading,
                  held: _tuner.held,
                  tolerance: settings.inTuneCents,
                  listening: _tuner.isListening,
                )
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
          // Listening starts and stops from the middle of the dial, like the
          // other two tabs; the row below is the reference A, in the same
          // pieces as the rows of the metronome and the harmony.
          lower: const ReferencePitchRow(),
          // Chromatic, or the open strings of a violin or a bass.
          footer: _TuningSwitch(settings: settings),
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

String _tuningName(AppLocalizations l10n, TunerTuning tuning) =>
    switch (tuning) {
      TunerTuning.chromatic => l10n.tuningChromatic,
      TunerTuning.guitar => l10n.tuningGuitar,
      TunerTuning.violin => l10n.tuningViolin,
      TunerTuning.viola => l10n.tuningViola,
      TunerTuning.cello => l10n.tuningCello,
      TunerTuning.ukulele => l10n.tuningUkulele,
      TunerTuning.bass => l10n.tuningBass,
      TunerTuning.bassFive => l10n.tuningBassFive,
    };

/// Chromatic, or the strings of an instrument chosen from a menu, in the
/// third row: with strings, the tuner names the nearest open string, its
/// number, and says how far off it is. The last instrument stays chosen.
class _TuningSwitch extends StatelessWidget {
  const _TuningSwitch({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final names = settings.noteNames(Localizations.localeOf(context));
    String strings(TunerTuning t) => l10n.tuningStrings(
      t.strings
          .map((n) => n.label(names, numbering: settings.octaveNumbering))
          .join(' '),
    );
    final chromatic = settings.tunerChromatic;
    return Row(
      key: const Key('tuningSwitch'),
      children: [
        Expanded(
          child: _TuningChoice(
            key: const Key('tuningChromatic'),
            selected: chromatic,
            onTap: () => settings.setTunerChromatic(true),
            child: Text(l10n.tuningChromatic, maxLines: 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: PopupMenuButton<TunerTuning>(
            key: const Key('tuningInstrument'),
            tooltip: l10n.tuningInstrument,
            position: PopupMenuPosition.over,
            initialValue: settings.tunerInstrument,
            onOpened: () => settings.setTunerChromatic(false),
            onSelected: settings.setTunerInstrument,
            itemBuilder: (context) => [
              for (final t in TunerTuning.instruments)
                PopupMenuItem(
                  value: t,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_tuningName(l10n, t)),
                      Text(
                        strings(t),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            child: _TuningChoice(
              selected: !chromatic,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tuningName(l10n, settings.tunerInstrument),
                    maxLines: 1,
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One of the two choices of [_TuningSwitch], drawn like a selected or
/// unselected segment of the buttons in the other rows.
class _TuningChoice extends StatelessWidget {
  const _TuningChoice({
    super.key,
    required this.selected,
    required this.child,
    this.onTap,
  });

  final bool selected;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: scheme.outline)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Center(
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                child: FittedBox(fit: BoxFit.scaleDown, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Green when in tune, ochre when close, red when far off: the shades live
/// in lib/app/theme.dart and keep at least 3:1 contrast (WCAG 1.4.3, 1.4.11).
Color _centsColor(ThemeData theme, double cents, double tolerance) {
  final colors = theme.extension<LowEndColors>()!;
  final off = cents.abs();
  if (off <= tolerance) return colors.inTune;
  if (off <= math.max(15, tolerance)) return colors.close;
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
    required this.held,
    required this.tolerance,
    required this.listening,
    required this.names,
    required this.numbering,
    required this.onToggle,
  });

  final TunerReading? reading;

  /// The note is only kept on screen while the string dies away.
  final bool held;

  /// How many cents either side of a note count as in tune.
  final double tolerance;
  final bool listening;
  final NoteNames names;
  final OctaveNumbering numbering;

  /// Touching the middle pauses or resumes listening.
  final VoidCallback onToggle;

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
    // A note that is only held stands still: it is not being heard.
    final cents = widget.held ? 0.0 : (widget.reading?.cents ?? 0);
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
    final segments = r == null || widget.held
        ? theme.colorScheme.outlineVariant
        : _centsColor(theme, r.cents, widget.tolerance);
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
        // The hub is the button: as wide as the hub of the dial.
        Center(
          child: FractionallySizedBox(
            widthFactor: DialGeometry.hubFraction,
            heightFactor: DialGeometry.hubFraction,
            child: Semantics(
              button: true,
              label: widget.listening
                  ? AppLocalizations.of(context).stopListening
                  : AppLocalizations.of(context).startListening,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: const Key('tunerHub'),
                  customBorder: const CircleBorder(),
                  onTap: widget.onToggle,
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.5 / DialGeometry.hubFraction,
                      heightFactor: 0.5 / DialGeometry.hubFraction,
                      child: _NoteDisplay(
                        reading: r,
                        held: widget.held,
                        tolerance: widget.tolerance,
                        listening: widget.listening,
                        names: widget.names,
                        numbering: widget.numbering,
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

    // A fixed reference at 12 o'clock across both bands: the segments stand
    // still against it when in tune.
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
    required this.held,
    required this.tolerance,
    required this.listening,
    required this.names,
    required this.numbering,
  });

  final TunerReading? reading;
  final bool held;
  final double tolerance;
  final bool listening;
  final NoteNames names;
  final OctaveNumbering numbering;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final r = reading;
    // Fixed sizes, the same as on the other two dials; large text on the
    // phone shrinks the whole block to fit rather than overflow.
    Widget fit(List<Widget> children) => Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
    if (!listening) {
      // Paused: what touching the middle does.
      return fit([
        Icon(Icons.mic, size: 32, color: theme.colorScheme.primary),
        Text(l10n.startListening, style: muted, textAlign: TextAlign.center),
      ]);
    }
    if (r == null) {
      return fit([
        Text('–', style: _noteStyle(theme)),
        Text(l10n.playAString, style: muted, textAlign: TextAlign.center),
      ]);
    }
    final cents = r.cents.round();
    final direction = r.inTune
        ? l10n.inTune
        : (cents < 0 ? l10n.flat : l10n.sharp);
    // A real minus sign: the hyphen is too short next to the plus.
    final centsText = l10n.centsValue(
      cents > 0 ? '+$cents' : (cents < 0 ? '−${-cents}' : '$cents'),
    );
    final color = _centsColor(theme, r.cents, tolerance);
    // Screen readers hear the note and whether it is flat, sharp or in tune,
    // only when that changes: reading every cent aloud would never stop.
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '${r.target.label(names, numbering: numbering)}, $direction'
          '${r.onStrings && r.played != r.target ? ', ${l10n.tunerHeard(r.played.label(names, numbering: numbering))}' : ''}',
      child: ExcludeSemantics(
        // A note that is only held fades: the string has stopped.
        child: Opacity(
          opacity: held ? 0.55 : 1,
          child: fit([
            _NoteName(
              note: r.target,
              names: names,
              numbering: numbering,
              color: color,
            ),
            // The verdict, large enough to read from the music stand.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A shape as well as a colour, for colour-blind players.
                Icon(
                  r.inTune
                      ? Icons.check_circle
                      : (cents < 0 ? Icons.arrow_downward : Icons.arrow_upward),
                  color: color,
                  size: LowEndType.headline,
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
            // With strings: the string being tuned, and what was heard when
            // it is not that one.
            if (r.onStrings) ...[
              if (r.stringNumber case final n?)
                Text(
                  l10n.tunerString(romanNumeral(n)),
                  style: muted?.copyWith(fontWeight: FontWeight.w700),
                ),
              if (r.played != r.target)
                Text(
                  l10n.tunerHeard(r.played.label(names, numbering: numbering)),
                  style: muted,
                ),
            ],
            Text(
              // A held note says so in words, not only by fading.
              held
                  ? l10n.tunerHeld
                  : l10n.frequencyHz(r.frequency.toStringAsFixed(1)),
              style: muted,
            ),
          ]),
        ),
      ),
    );
  }
}

TextStyle? _noteStyle(ThemeData theme) =>
    theme.textTheme.displayMedium?.copyWith(height: 1.05);

/// The note name, large, with its octave smaller beside it.
class _NoteName extends StatelessWidget {
  const _NoteName({
    required this.note,
    required this.names,
    required this.numbering,
    required this.color,
  });

  final Note note;
  final NoteNames names;
  final OctaveNumbering numbering;
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
            text: '${note.octaveIn(names, numbering: numbering)}',
            style: LowEndType.octave(style),
          ),
        ],
      ),
      style: style,
      textAlign: TextAlign.center,
    );
  }
}

/// A straight scale of the cents, 50 flat to 50 sharp, in the first row
/// under the dial: a marker on it says how far off the note is, with the
/// "in tune" zone shaded. The strobe shows the same thing by turning, which
/// is hard to read at a glance, and this by position, which is not.
class _CentsBar extends StatelessWidget {
  const _CentsBar({
    required this.reading,
    required this.held,
    required this.tolerance,
    required this.listening,
  });

  final TunerReading? reading;
  final bool held;
  final double tolerance;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LowEndColors.of(context);
    final r = reading;
    final show = listening && r != null;
    // The note and its verdict are read by the middle of the dial.
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: CustomPaint(
            painter: _CentsBarPainter(
              cents: show ? r.cents : null,
              marker: show && !held
                  ? _centsColor(theme, r.cents, tolerance)
                  : theme.colorScheme.outline,
              zone: colors.inTune,
              tolerance: tolerance,
              scale: theme.colorScheme.outline,
              hub: theme.colorScheme.surface,
            ),
          ),
        ),
      ),
    );
  }
}

class _CentsBarPainter extends CustomPainter {
  _CentsBarPainter({
    required this.cents,
    required this.marker,
    required this.zone,
    required this.tolerance,
    required this.scale,
    required this.hub,
  });

  final double? cents;
  final Color marker;
  final Color zone;
  final double tolerance;
  final Color scale;
  final Color hub;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    double x(double c) =>
        size.width / 2 + c.clamp(-50, 50) / 50 * size.width / 2;
    // The in-tune zone behind the ticks.
    canvas.drawRRect(
      RRect.fromLTRBR(
        x(-tolerance),
        mid - 14,
        x(tolerance),
        mid + 14,
        const Radius.circular(6),
      ),
      Paint()..color = zone.withValues(alpha: 0.28),
    );
    final tick = Paint()
      ..color = scale
      ..strokeWidth = 2;
    for (var c = -50; c <= 50; c += 10) {
      // The tick for "in tune" is longer and thicker: told by shape.
      final zero = c == 0;
      canvas.drawLine(
        Offset(x(c.toDouble()), mid - (zero ? 14 : 7)),
        Offset(x(c.toDouble()), mid + (zero ? 14 : 7)),
        zero
            ? (Paint()
                ..color = scale
                ..strokeWidth = 4)
            : tick,
      );
    }
    final c = cents;
    if (c == null) return;
    // A round marker on the scale, with a halo against the ticks.
    final at = Offset(x(c), mid);
    canvas.drawCircle(at, 11, Paint()..color = hub);
    canvas.drawCircle(at, 8, Paint()..color = marker);
  }

  @override
  bool shouldRepaint(_CentsBarPainter old) =>
      old.cents != cents ||
      old.marker != marker ||
      old.zone != zone ||
      old.tolerance != tolerance ||
      old.scale != scale ||
      old.hub != hub;
}
