import 'package:flutter/material.dart';

import '../../audio/audio_scope.dart';
import '../../audio/pitch.dart';
import '../../l10n/app_localizations.dart';
import 'reference_pitch_picker.dart';
import 'tuner_controller.dart';
import 'tunings.dart';

/// The tuner: listens to the microphone and shows how far the note played is
/// from the nearest open string (or the nearest note, in chromatic mode).
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
    // Stop listening when the app goes to the background.
    _lifecycle = AppLifecycleListener(onHide: () => _tuner.stop());
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
            _TuningPicker(tuner: _tuner, language: language),
            const SizedBox(height: 24),
            _NoteDisplay(
              reading: reading,
              listening: _tuner.isListening,
              language: language,
            ),
            const SizedBox(height: 16),
            _CentsGauge(cents: reading?.cents),
            const SizedBox(height: 8),
            if (_tuner.tuning case final tuning?)
              _StringRow(
                tuning: tuning,
                target: reading?.target,
                language: language,
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

class _TuningPicker extends StatelessWidget {
  const _TuningPicker({required this.tuner, required this.language});

  final TunerController tuner;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String instrument(Instrument i) => switch (i) {
      Instrument.doubleBass => l10n.doubleBass,
      Instrument.electricBass => l10n.electricBass,
    };
    return DropdownButtonFormField<Tuning?>(
      initialValue: tuner.tuning,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.tuningLabel,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.chromatic)),
        for (final t in tunings)
          DropdownMenuItem(
            value: t,
            child: Text(
              '${instrument(t.instrument)} · ${l10n.tuningName(t.id)} '
              '(${t.strings.map((n) => n.name(language)).join(' ')})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: tuner.setTuning,
    );
  }
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
          Text('–', style: theme.textTheme.displayLarge),
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
            Text(
              r.target.label(language),
              style: theme.textTheme.displayLarge?.copyWith(
                color: _centsColor(theme, r.cents),
                fontWeight: FontWeight.w600,
              ),
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
              r.played == r.target
                  ? l10n.frequencyHz(r.frequency.toStringAsFixed(1))
                  : '${l10n.playingNote(r.played.label(language))} · '
                        '${l10n.frequencyHz(r.frequency.toStringAsFixed(1))}',
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

/// The open strings of the chosen tuning, with the one being tuned lit up.
class _StringRow extends StatelessWidget {
  const _StringRow({
    required this.tuning,
    required this.target,
    required this.language,
  });

  final Tuning tuning;
  final Note? target;
  final String language;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final string in tuning.strings)
          Semantics(
            selected: string == target,
            child: Chip(
              label: Text(
                string.label(language),
                style: TextStyle(
                  color: string == target
                      ? colors.onPrimary
                      : colors.onSurfaceVariant,
                  // Bold as well as coloured, so it doesn't rely on colour.
                  fontWeight: string == target ? FontWeight.bold : null,
                ),
              ),
              backgroundColor: string == target ? colors.primary : null,
            ),
          ),
      ],
    );
  }
}
