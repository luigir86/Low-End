import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme.dart';
import '../../audio/audio_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dial.dart';
import 'metronome_controller.dart';

/// The metronome, in 4/4: a ring of four segments lights up clockwise, one
/// per beat (top, right, bottom, left), with the "one" at the top in its
/// own colour, and a dot in the middle swells on every beat. Touching the
/// ring starts and stops it; the tempo sits below, with − and + and TAP.
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
        lower: _TapButton(metronome: metronome),
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
      value: l10n.bpmValue('${metronome.bpm}'),
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
                    frame: _frame,
                    colors: theme.colorScheme,
                    background: LowEndColors.of(context).strobeBackground,
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
    required ValueNotifier<int> frame,
    required this.colors,
    required this.background,
    required this.pulse,
  }) : super(repaint: frame);

  final MetronomeController metronome;
  final ColorScheme colors;
  final Color background;
  final bool pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final dial = DialGeometry(size);
    dial.paintBase(canvas, disc: background, hub: colors.surface);

    final beat = metronome.beat;
    const quarter = math.pi / 2;
    for (var b = 0; b < MetronomeController.beatsPerBar; b++) {
      // Beat 0 is centred at the top, then clockwise.
      dial.paintSegment(
        canvas,
        startAngle: b * quarter - quarter / 2 + DialGeometry.gap / 2,
        sweep: quarter - DialGeometry.gap,
        color: b == beat
            ? (b == 0 ? colors.tertiary : colors.primary)
            : colors.outlineVariant,
      );
    }

    // The dot in the hub.
    final since = metronome.sinceBeat;
    if (beat == null || since == null) return;
    var radius = dial.hub * 0.3;
    if (pulse) {
      // Swells at once on the beat, then shrinks back before the next one.
      final decay = math.min(0.12, metronome.beatLength.inMicroseconds / 3e6);
      radius += dial.hub * 0.25 * math.exp(-since.inMicroseconds / 1e6 / decay);
    }
    canvas.drawCircle(
      dial.center,
      radius,
      Paint()..color = beat == 0 ? colors.tertiary : colors.secondary,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.metronome != metronome ||
      old.colors != colors ||
      old.background != background ||
      old.pulse != pulse;
}

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
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140),
            child: Semantics(
              liveRegion: true,
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
                  Text(
                    'BPM',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _RepeatButton(
          icon: Icons.add,
          tooltip: l10n.faster,
          onStep: metronome.bpm < MetronomeController.maxBpm
              ? () => metronome.step(1)
              : null,
        ),
      ],
    );
  }
}

/// A round button that steps once when tapped, and keeps stepping, faster
/// and faster, while held.
class _RepeatButton extends StatefulWidget {
  const _RepeatButton({
    required this.icon,
    required this.tooltip,
    required this.onStep,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onStep;

  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  Timer? _timer;
  var _steps = 0;

  void _startRepeat() {
    _steps = 0;
    _schedule();
  }

  void _schedule() {
    // 6 steps a second at first, then 20.
    final delay = Duration(milliseconds: _steps < 8 ? 160 : 50);
    _timer = Timer(delay, () {
      final step = widget.onStep;
      if (step == null) return _stopRepeat();
      step();
      _steps++;
      _schedule();
    });
  }

  void _stopRepeat() {
    _timer?.cancel();
    _timer = null;
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
