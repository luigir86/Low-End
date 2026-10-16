import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme.dart';
import '../../audio/audio_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/balance_slider.dart';
import '../../widgets/dial.dart';
import 'metronome_controller.dart';
import 'tempo_dialog.dart';
import 'time_signature.dart';

/// The metronome: a ring with one segment per beat of the bar (4 in 4/4,
/// 6 in 6/8, and so on) lights up clockwise from 12 o'clock, with the "one"
/// in its own colour, and a dot in the middle swells on every beat. In
/// bars felt in groups (6/8) wider gaps split the groups. Touching the ring
/// starts and stops it; the tempo sits below, with − and + and TAP.
class MetronomeScreen extends StatelessWidget {
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = AudioScope.of(context).metronome;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: metronome,
      builder: (context, _) => DialLayout(
        dial: _BeatRing(metronome: metronome),
        upper: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TempoControls(metronome: metronome),
            if (metronome.audioFailed)
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
        lower: Row(
          children: [
            _SignatureButton(metronome: metronome),
            const SizedBox(width: 12),
            Expanded(child: _TapButton(metronome: metronome)),
          ],
        ),
        footer: const BalanceSlider(),
      ),
    );
  }
}

/// The ring and the dot; touching it starts or stops the metronome.
class _BeatRing extends StatefulWidget {
  const _BeatRing({required this.metronome});

  final MetronomeController metronome;

  @override
  State<_BeatRing> createState() => _BeatRingState();
}

class _BeatRingState extends State<_BeatRing>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => _frame.value++);

  /// Bumped on every frame while playing, to repaint the ring.
  final _frame = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_BeatRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Runs frames only while the metronome plays, to save battery.
  void _sync() {
    final playing = widget.metronome.isPlaying;
    if (playing && !_ticker.isActive) _ticker.start();
    if (!playing && _ticker.isActive) {
      _ticker.stop();
      _frame.value++;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final metronome = widget.metronome;
    final playing = metronome.isPlaying;
    return Semantics(
      button: true,
      label: playing ? l10n.metronomeStop : l10n.metronomeStart,
      value:
          '${l10n.bpmValue('${metronome.bpm}')}, '
          '${beatUnitName(l10n, metronome.signature.beatUnit)}',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: metronome.toggle,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: _RingPainter(
                    metronome: metronome,
                    signature: metronome.signature,
                    frame: _frame,
                    colors: theme.colorScheme,
                    background: LowEndColors.of(context).strobeBackground,
                    downbeat: LowEndColors.of(context).downbeat,
                    // A dot that swells is motion: with animations turned
                    // off it only changes colour.
                    pulse: !MediaQuery.disableAnimationsOf(context),
                  ),
                ),
              ),
              if (!playing)
                FractionallySizedBox(
                  widthFactor: 0.45,
                  heightFactor: 0.45,
                  child: FittedBox(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 72,
                          color: theme.colorScheme.primary,
                        ),
                        Text(
                          l10n.metronomeHint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.metronome,
    required this.signature,
    required ValueNotifier<int> frame,
    required this.colors,
    required this.background,
    required this.downbeat,
    required this.pulse,
  }) : super(repaint: frame);

  final MetronomeController metronome;

  /// The time signature drawn: kept here so that a new one repaints the ring
  /// at once, also while the metronome is stopped and nothing else does.
  final TimeSignature signature;
  final ColorScheme colors;
  final Color background;

  /// The colour of the "one".
  final Color downbeat;
  final bool pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final dial = DialGeometry(size);
    dial.paintBase(canvas, disc: background, hub: colors.surface);

    final beat = metronome.beat;
    final count = signature.beats;
    final slice = 2 * math.pi / count;
    // Wider gaps between the groups of a bar such as 6/8, so that it does
    // not look like 3/4 with twice the segments.
    const groupGap = 0.14;
    for (var b = 0; b < count; b++) {
      final opens = signature.grouped && signature.accent(b) < 2;
      final closes = signature.grouped && signature.accent((b + 1) % count) < 2;
      final start = DialGeometry.gap / 2 + (opens ? groupGap / 2 : 0);
      final end = DialGeometry.gap / 2 + (closes ? groupGap / 2 : 0);
      // Beat 0 starts at 12 o'clock, then clockwise.
      final Color color;
      if (b != beat) {
        color = colors.outlineVariant;
      } else if (b == 0) {
        color = downbeat;
      } else if (signature.grouped && !opens) {
        // The weak pulses of a group are softer than its first.
        color = colors.primary.withValues(alpha: 0.6);
      } else {
        color = colors.primary;
      }
      dial.paintSegment(
        canvas,
        startAngle: b * slice + start,
        sweep: slice - start - end,
        color: color,
        border: b == beat ? null : colors.outline,
      );
    }

    // Waiting for the piano's bar line: the seconds to go, in the hub.
    final left = metronome.waitLeft;
    if (left != null && left >= const Duration(milliseconds: 500)) {
      final seconds = (left.inMilliseconds / 1000).ceil();
      final text = TextPainter(
        text: TextSpan(
          text: '$seconds',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: dial.hub * 0.9,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, dial.center - Offset(text.width / 2, text.height / 2));
      return;
    }

    // The dot in the hub.
    final since = metronome.sinceBeat;
    if (beat == null || since == null) return;
    var radius = dial.hub * 0.3;
    if (pulse) {
      // Swells at once on the beat, then shrinks back before the next one.
      final decay = math.min(0.12, metronome.pulseLength.inMicroseconds / 3e6);
      radius += dial.hub * 0.25 * math.exp(-since.inMicroseconds / 1e6 / decay);
    }
    canvas.drawCircle(
      dial.center,
      radius,
      Paint()..color = beat == 0 ? downbeat : colors.secondary,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.metronome != metronome ||
      old.signature != signature ||
      old.colors != colors ||
      old.background != background ||
      old.downbeat != downbeat ||
      old.pulse != pulse;
}

/// What the tempo counts, under its number: "♩ BPM", "♪ BPM" in 7/8, and
/// in the compound bars "♩. BPM · ♪ = 180", the eighths too.
String tempoUnitCaption(TimeSignature signature, int bpm) {
  final caption = '${signature.beatUnit.symbol} BPM';
  if (!signature.compound) return caption;
  return '$caption · ${BeatUnit.eighth.symbol} = '
      '${bpm * signature.pulsesPerBeat}';
}

/// The figure the tempo counts, for screen readers.
String beatUnitName(AppLocalizations l10n, BeatUnit unit) => switch (unit) {
  BeatUnit.quarter => l10n.beatUnitQuarter,
  BeatUnit.dottedQuarter => l10n.beatUnitDottedQuarter,
  BeatUnit.eighth => l10n.beatUnitEighth,
};

/// − BPM +, with the buttons repeating while held.
class _TempoControls extends StatelessWidget {
  const _TempoControls({required this.metronome});

  final MetronomeController metronome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RepeatButton(
          icon: Icons.remove,
          tooltip: l10n.slower,
          onStep: metronome.bpm > MetronomeController.minBpm
              ? () => metronome.step(-1)
              : null,
          onHold: (unit) => metronome.nudge(-1, unit),
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140),
            // Touching the number opens the keyboard to type the tempo.
            child: MergeSemantics(
              child: Semantics(
                liveRegion: true,
                button: true,
                hint: l10n.setTempo,
                onTap: () => showTempoDialog(context, metronome),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showTempoDialog(context, metronome),
                  child: Column(
                    children: [
                      FittedBox(
                        child: Text(
                          '${metronome.bpm}',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // The figure the tempo counts: "♩. BPM" in 6/8, with the
                      // eighths it makes.
                      FittedBox(
                        child: Text(
                          tempoUnitCaption(metronome.signature, metronome.bpm),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _RepeatButton(
          icon: Icons.add,
          tooltip: l10n.faster,
          onStep: metronome.bpm < metronome.maxTempo
              ? () => metronome.step(1)
              : null,
          onHold: (unit) => metronome.nudge(1, unit),
        ),
      ],
    );
  }
}

/// A round button that steps by one when tapped, and when held keeps going
/// by fives (to the next multiple of 5), then by tens after a couple of
/// seconds.
class _RepeatButton extends StatefulWidget {
  const _RepeatButton({
    required this.icon,
    required this.tooltip,
    required this.onStep,
    required this.onHold,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onStep;

  /// Called again and again while held, with the size of the step.
  final void Function(int unit) onHold;

  /// How long the steps of 5 last before they become steps of 10.
  static const _tensAfter = Duration(seconds: 2);
  static const _every = Duration(milliseconds: 220);

  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  Timer? _timer;
  final _held = Stopwatch();

  void _startRepeat() {
    _held
      ..reset()
      ..start();
    // The first step comes at once, as the hold is recognised.
    _tick();
  }

  void _tick() {
    if (widget.onStep == null) return _stopRepeat();
    widget.onHold(_held.elapsed < _RepeatButton._tensAfter ? 5 : 10);
    _timer = Timer(_RepeatButton._every, _tick);
  }

  void _stopRepeat() {
    _timer?.cancel();
    _timer = null;
    _held.stop();
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // The IconButton below speaks for it; holding is a shortcut.
      excludeFromSemantics: true,
      onLongPressStart: widget.onStep == null ? null : (_) => _startRepeat(),
      onLongPressEnd: (_) => _stopRepeat(),
      onLongPressCancel: _stopRepeat,
      child: IconButton.outlined(
        iconSize: 28,
        constraints: const BoxConstraints.tightFor(width: 64, height: 64),
        icon: Icon(widget.icon),
        tooltip: widget.tooltip,
        onPressed: widget.onStep,
      ),
    );
  }
}

/// Shows the time signature and opens the list to choose another.
class _SignatureButton extends StatelessWidget {
  const _SignatureButton({required this.metronome});

  final MetronomeController metronome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final signature = metronome.signature;
    return Semantics(
      label: l10n.timeSignature,
      value: signature.label,
      button: true,
      excludeSemantics: true,
      onTap: () => _choose(context),
      child: OutlinedButton(
        onPressed: () => _choose(context),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 64),
          textStyle: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        // The name of the button above the bar, "Time signature" over 4/4.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                l10n.timeSignature,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Text(signature.label),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<TimeSignature>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.timeSignature,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final s in TimeSignature.all)
                ListTile(
                  title: Text(s.label),
                  // How the bar is felt: 3/4 is "3", 6/8 is "3 + 3".
                  subtitle: s.grouped ? Text(s.feel) : null,
                  selected: s == metronome.signature,
                  trailing: s == metronome.signature
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(s),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) metronome.setSignature(picked);
  }
}

class _TapButton extends StatefulWidget {
  const _TapButton({required this.metronome});

  final MetronomeController metronome;

  @override
  State<_TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<_TapButton> {
  final _clock = Stopwatch()..start();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void tap() => widget.metronome.tap(_clock.elapsed);
    return Semantics(
      label: l10n.tapTempo,
      button: true,
      excludeSemantics: true,
      // A screen reader's double tap counts as one tap.
      onTap: tap,
      child: Listener(
        // On touch down, not on release: the tap lands with the hand.
        onPointerDown: (_) => tap(),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            // The tap is counted by the Listener; this only shows the ripple.
            onPressed: () {},
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(64),
              textStyle: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 2),
            ),
            child: const Text('TAP'),
          ),
        ),
      ),
    );
  }
}
