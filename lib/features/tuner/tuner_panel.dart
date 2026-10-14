import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../audio/audio_scope.dart';
import '../../audio/pitch.dart';
import '../../l10n/app_localizations.dart';
import 'reference_pitch_picker.dart';
import 'tuner_controller.dart';
import 'tunings.dart';

/// The tuner: listens to the microphone, names whatever note it hears (no
/// tuning to choose) and shows how far off it is on a strobe, like the
/// Peterson tuners many bassists know.
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
    final drone = AudioScope.of(context).drone;
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_tuner, drone]),
      builder: (context, _) {
        final hz = _tuner.frequency;
        final reading = hz == null
            ? null
            : TunerReading.of(hz, tuning: _tuner.tuning, a4: drone.a4);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            _NoteDisplay(
              reading: reading,
              listening: _tuner.isListening,
              language: language,
            ),
            const SizedBox(height: 16),
            // Moves on every frame: repaint only this part of the screen.
            RepaintBoundary(
              child: MediaQuery.disableAnimationsOf(context)
                  // A still needle for players who turned animations off.
                  ? _CentsGauge(cents: reading?.cents)
                  : _Strobe(cents: reading?.cents),
            ),
            const SizedBox(height: 24),
            Center(
              child: FilledButton.icon(
                onPressed: _tuner.toggle,
                icon: Icon(_tuner.isListening ? Icons.mic_off : Icons.mic),
                label: Text(
                  _tuner.isListening ? l10n.stopListening : l10n.startListening,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 56),
                  textStyle: theme.textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_statusMessage(l10n) case final message?)
              // Announced by screen readers, e.g. when the microphone is denied.
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
            const SizedBox(height: 16),
            ReferencePitchPicker(drone: drone),
          ],
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

class _NoteDisplay extends StatelessWidget {
  const _NoteDisplay({
    required this.reading,
    required this.listening,
    required this.language,
  });

  final TunerReading? reading;
  final bool listening;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final r = reading;
    if (r == null) {
      return Column(
        children: [
          Text('–', style: _noteStyle(theme)),
          Text(listening ? l10n.playAString : '', style: muted),
        ],
      );
    }
    final cents = r.cents.round();
    final direction = r.inTune
        ? l10n.inTune
        : (cents < 0 ? l10n.flat : l10n.sharp);
    final verdict = r.inTune
        ? l10n.inTune
        : '$direction · '
              '${l10n.centsValue('${cents > 0 ? '+' : ''}$cents')}';
    // Screen readers hear the note and whether it is flat, sharp or in tune,
    // only when that changes: reading every cent aloud would never stop.
    return Semantics(
      liveRegion: true,
      label: '${r.target.label(language)}, $direction',
      child: ExcludeSemantics(
        child: Column(
          children: [
            _NoteName(
              note: r.target,
              language: language,
              color: _centsColor(theme, r.cents),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // A shape as well as a colour, for colour-blind players.
                if (r.inTune) ...[
                  Icon(Icons.check_circle, color: _centsColor(theme, 0)),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(verdict, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            Text(
              l10n.frequencyHz(r.frequency.toStringAsFixed(1)),
              style: muted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Green when in tune, amber when close, red when far off.
///
/// Darker shades on light backgrounds and lighter ones on dark backgrounds,
/// so the note and the needle keep at least 3:1 contrast (WCAG 1.4.3, 1.4.11).
Color _centsColor(ThemeData theme, double cents) {
  final dark = theme.brightness == Brightness.dark;
  final off = cents.abs();
  if (off <= TunerReading.inTuneCents) {
    return dark ? Colors.green.shade300 : Colors.green.shade800;
  }
  if (off <= 15) return dark ? Colors.amber.shade300 : const Color(0xFF8A5A00);
  return theme.colorScheme.error;
}

/// A horizontal scale from -50 to +50 cents with a needle.
class _CentsGauge extends StatelessWidget {
  const _CentsGauge({required this.cents});

  final double? cents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = cents;
    return Column(
      children: [
        // The note display above already says all of this in words.
        ExcludeSemantics(
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (c ?? 0).clamp(-50, 50)),
              duration: const Duration(milliseconds: 120),
              builder: (context, value, _) => CustomPaint(
                painter: _GaugePainter(
                  cents: c == null ? null : value,
                  scale: theme.colorScheme.outline,
                  needle: c == null
                      ? theme.colorScheme.outlineVariant
                      : _centsColor(theme, c),
                  zone: _centsColor(theme, 0).withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
        ),
        ExcludeSemantics(
          child: Row(
            children: [
              Text('♭', style: theme.textTheme.titleLarge),
              const Spacer(),
              Text('♯', style: theme.textTheme.titleLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.cents,
    required this.scale,
    required this.needle,
    required this.zone,
  });

  final double? cents;
  final Color scale;
  final Color needle;
  final Color zone;

  @override
  void paint(Canvas canvas, Size size) {
    double x(double c) => size.width / 2 + c / 50 * (size.width / 2 - 8);
    final mid = size.height / 2;

    // The in-tune zone.
    canvas.drawRect(
      Rect.fromLTRB(
        x(-TunerReading.inTuneCents),
        0,
        x(TunerReading.inTuneCents),
        size.height,
      ),
      Paint()..color = zone,
    );
    final tick = Paint()
      ..color = scale
      ..strokeWidth = 1.5;
    for (var c = -50; c <= 50; c += 10) {
      final long = c == 0 ? 0.0 : (c % 50 == 0 ? 10.0 : 16.0);
      canvas.drawLine(
        Offset(x(c.toDouble()), long),
        Offset(x(c.toDouble()), size.height - long),
        tick,
      );
    }
    canvas.drawLine(Offset(x(-50), mid), Offset(x(50), mid), tick);

    if (cents case final c?) {
      canvas.drawLine(
        Offset(x(c), 0),
        Offset(x(c), size.height),
        Paint()
          ..color = needle
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.cents != cents || old.needle != needle || old.scale != scale;
}

TextStyle? _noteStyle(ThemeData theme) =>
    theme.textTheme.displayLarge?.copyWith(fontSize: 96, height: 1.1);

/// The note name, large, with its octave smaller beside it: "A₁".
class _NoteName extends StatelessWidget {
  const _NoteName({
    required this.note,
    required this.language,
    required this.color,
  });

  final Note note;
  final String language;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = _noteStyle(Theme.of(context))
        ?.copyWith(color: color, fontWeight: FontWeight.w600);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: note.name(language)),
          TextSpan(
            text: '${note.octave}',
            style: TextStyle(fontSize: (style?.fontSize ?? 96) * 0.4),
          ),
        ],
      ),
      style: style,
      textAlign: TextAlign.center,
    );
  }
}

/// A strobe like those of Peterson tuners: bands of stripes drift left when
/// the note is flat and right when it is sharp, faster the further off it
/// is, and stand still when it is spot on. The lower band moves twice as
/// fast as the upper one, so it shows even a cent or two.
class _Strobe extends StatefulWidget {
  const _Strobe({required this.cents});

  final double? cents;

  @override
  State<_Strobe> createState() => _StrobeState();
}

class _StrobeState extends State<_Strobe> with SingleTickerProviderStateMixin {
  /// Stripes per second for each cent off, in the upper band.
  static const _speed = 0.5;

  /// Fastest drift, in stripes per second: beyond this the eye loses track.
  static const _maxSpeed = 6.0;

  late final Ticker _ticker = createTicker(_tick);
  final _phase = ValueNotifier<double>(0);
  var _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Strobe oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Runs the animation only while a note is heard, to save battery.
  void _sync() {
    final hearing = widget.cents != null;
    if (hearing && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!hearing && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final seconds = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final cents = widget.cents ?? 0;
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
    final c = widget.cents;
    return ExcludeSemantics(
      child: SizedBox(
        height: 88,
        width: double.infinity,
        child: CustomPaint(
          painter: _StrobePainter(
            phase: _phase,
            stripes: c == null
                ? theme.colorScheme.outlineVariant
                : _centsColor(theme, c),
            background: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}

class _StrobePainter extends CustomPainter {
  _StrobePainter({
    required this.phase,
    required this.stripes,
    required this.background,
  }) : super(repaint: phase);

  final ValueNotifier<double> phase;
  final Color stripes;
  final Color background;

  static const _stripe = 14.0;
  static const _gap = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.drawRRect(frame, Paint()..color = background);
    canvas.save();
    canvas.clipRRect(frame);
    final paint = Paint()..color = stripes;
    final bandHeight = (size.height - _gap * 3) / 2;
    for (var band = 0; band < 2; band++) {
      final top = _gap + band * (bandHeight + _gap);
      final shift = (phase.value * (band + 1) % 1) * _stripe * 2;
      for (var x = shift - _stripe * 2; x < size.width; x += _stripe * 2) {
        canvas.drawRect(Rect.fromLTWH(x, top, _stripe, bandHeight), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StrobePainter old) =>
      old.stripes != stripes || old.background != background;
}
