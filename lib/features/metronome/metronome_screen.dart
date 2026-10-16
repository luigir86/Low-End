import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/style.dart';
import '../../app/theme.dart';
import '../../audio/audio_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/balance_slider.dart';
import '../../widgets/dial.dart';
import '../../widgets/row_controls.dart';
import 'feel.dart';
import 'metronome_controller.dart';
import 'tempo_dialog.dart';
import 'time_signature.dart';

/// The metronome: a ring with one segment per beat of the bar (4 in 4/4,
/// 6 in 6/8, and so on) lights up clockwise from 12 o'clock, with the "one"
/// in its own colour, and the tempo in the middle. In bars felt in groups
/// (6/8) wider gaps split the groups, and a bar of one beat is a single
/// segment that flashes. Touching the ring starts and stops it; below it,
/// the feel (straight, swing, shuffle), and a row like the harmony's with
/// the time signature, TAP, − + and a pencil to type the tempo.
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
        // How the beat is felt, as Root, Chord and Progression are chosen
        // on the harmony tab; and under it, in the row of the chord menu,
        // the time signature, TAP and the tempo: - + and the pencil.
        upper: _FeelSwitch(metronome: metronome),
        lower: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The same pieces as the chord row of the harmony tab: a field
            // with its name on the border, chips, an icon button.
            Row(
              children: [
                Expanded(child: _SignatureButton(metronome: metronome)),
                const SizedBox(width: 6),
                _TapButton(metronome: metronome),
                const SizedBox(width: 4),
                _StepButton(
                  icon: Icons.remove,
                  tooltip: l10n.slower,
                  onStep: metronome.bpm > MetronomeController.minBpm
                      ? () => metronome.step(-1)
                      : null,
                  onHold: (unit) => metronome.nudge(-1, unit),
                ),
                const SizedBox(width: 4),
                _StepButton(
                  icon: Icons.add,
                  tooltip: l10n.faster,
                  onStep: metronome.bpm < metronome.maxTempo
                      ? () => metronome.step(1)
                      : null,
                  onHold: (unit) => metronome.nudge(1, unit),
                ),
                RowIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: l10n.setTempo,
                  onPressed: () => showTempoDialog(context, metronome),
                ),
              ],
            ),
            if (metronome.audioFailed)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.audioUnavailable,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
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
  late final Ticker _ticker = createTicker(_onFrame);

  /// Bumped when the lit segment changes (or the metronome stops), to repaint
  /// the ring: the costly layer, which does not move between beats.
  final _ringFrame = ValueNotifier<int>(0);

  /// Bumped while the countdown shows, to repaint the hub.
  final _hubFrame = ValueNotifier<int>(0);

  int? _lastBeat;

  void _onFrame(Duration _) {
    final metronome = widget.metronome;
    final beat = metronome.beat;
    if (beat != _lastBeat) {
      _lastBeat = beat;
      _ringFrame.value++;
      _hubFrame.value++;
      return;
    }
    if (metronome.waitLeft != null) _hubFrame.value++;
    // A bar of one beat has a single segment: it flashes on the beat and
    // fades, so that the beat is seen.
    final since = metronome.sinceBeat;
    if (metronome.beatsPerBar == 1 &&
        since != null &&
        since < _RingPainter.flashTime(metronome)) {
      _ringFrame.value++;
    }
  }

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
      _lastBeat = null;
      _ringFrame.value++;
      _hubFrame.value++;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ringFrame.dispose();
    _hubFrame.dispose();
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
                    frame: _ringFrame,
                    colors: theme.colorScheme,
                    background: LowEndColors.of(context).strobeBackground,
                    downbeat: LowEndColors.of(context).downbeat,
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 0.5,
                child: ValueListenableBuilder<int>(
                  valueListenable: _hubFrame,
                  builder: (context, _, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _Hub(metronome: metronome, playing: playing),
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
  }) : super(repaint: frame);

  final MetronomeController metronome;

  /// The time signature drawn: kept here so that a new one repaints the ring
  /// at once, also while the metronome is stopped and nothing else does.
  final TimeSignature signature;
  final ColorScheme colors;
  final Color background;

  /// The colour of the "one".
  final Color downbeat;

  /// How fast the single segment of a one-beat bar fades.
  static double _decay(MetronomeController metronome) =>
      math.min(0.12, metronome.pulseLength.inMicroseconds / 3e6);

  /// After this long the flash is invisible: no more frames.
  static Duration flashTime(MetronomeController metronome) =>
      Duration(microseconds: (_decay(metronome) * 6e6).round());

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
      // A bar of one beat is the whole ring, with no gap.
      final whole = count == 1;
      final start = whole
          ? 0.0
          : DialGeometry.gap / 2 + (opens ? groupGap / 2 : 0);
      final end = whole
          ? 0.0
          : DialGeometry.gap / 2 + (closes ? groupGap / 2 : 0);
      // Beat 0 starts at 12 o'clock, then clockwise.
      var color = colors.outlineVariant;
      var flash = false;
      if (count == 1 && beat != null) {
        // The only segment is always "the beat": it flashes and fades.
        final since = metronome.sinceBeat ?? Duration.zero;
        final t = math.exp(-since.inMicroseconds / 1e6 / _decay(metronome));
        color = Color.lerp(colors.outlineVariant, downbeat, t)!;
        flash = t > 0.5;
      } else if (b != beat) {
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
        inner: dial.ringInner + dial.ringWidth * 0.22,
        outer: dial.ringOuter - dial.ringWidth * 0.08,
        startAngle: b * slice + start,
        sweep: slice - start - end,
        color: color,
        border: (count == 1 ? flash : b == beat) ? null : colors.outline,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.metronome != metronome ||
      old.signature != signature ||
      old.colors != colors ||
      old.background != background ||
      old.downbeat != downbeat;
}

/// What the hub shows: the tempo, or, while the click waits for the piano's
/// bar line, the seconds to go. Apart from the ring, so a frame of the
/// countdown repaints only this.
class _Hub extends StatelessWidget {
  const _Hub({required this.metronome, required this.playing});

  final MetronomeController metronome;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final left = metronome.waitLeft;
    final waiting = left != null && left >= const Duration(milliseconds: 500);
    final number = waiting
        ? (left.inMilliseconds / 1000).ceil()
        : metronome.bpm;
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$number',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: waiting
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        // What touching does, or the figure the tempo counts: "♩ BPM",
        // "♩. BPM · ♪ = 180" in 6/8.
        if (!waiting)
          Text(
            playing
                ? tempoUnitCaption(metronome.signature, metronome.bpm)
                : l10n.metronomeHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
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

/// How the beat is felt: straight, swing or shuffle, chosen as Root, Chord
/// and Progression are on the harmony tab. Bars counted in eighths are
/// always straight, so it is off there.
class _FeelSwitch extends StatelessWidget {
  const _FeelSwitch({required this.metronome});

  final MetronomeController metronome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget label(String text) =>
        FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
    return Semantics(
      label: l10n.feelLabel,
      container: true,
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<MetronomeFeel>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            minimumSize: const Size(0, LowEndShape.row),
          ),
          segments: [
            ButtonSegment(
              value: MetronomeFeel.straight,
              label: label(l10n.feelStraight),
            ),
            ButtonSegment(
              value: MetronomeFeel.swing,
              label: label(l10n.feelSwing),
            ),
            ButtonSegment(
              value: MetronomeFeel.shuffle,
              label: label(l10n.feelShuffle),
            ),
          ],
          selected: {metronome.feel},
          onSelectionChanged: metronome.feelApplies
              ? (s) => metronome.setFeel(s.first)
              : null,
        ),
      ),
    );
  }
}

/// A chip of the − + pair that steps by one when tapped, and when held
/// keeps going by fives (to the next multiple of 5), then by tens after a
/// couple of seconds.
class _StepButton extends StatefulWidget {
  const _StepButton({
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
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
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
    widget.onHold(_held.elapsed < _StepButton._tensAfter ? 5 : 10);
    _timer = Timer(_StepButton._every, _tick);
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
      // The chip below speaks for it; holding is a shortcut.
      excludeFromSemantics: true,
      onLongPressStart: widget.onStep == null ? null : (_) => _startRepeat(),
      onLongPressEnd: (_) => _stopRepeat(),
      onLongPressCancel: _stopRepeat,
      child: RowChip(
        label: Icon(widget.icon, size: 24),
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
    return LabeledField(
      label: l10n.timeSignature,
      // The border is bare: "4/4" in it needs no title (the label is still
      // what a screen reader announces).
      showLabel: false,
      value: signature.label,
      onTap: () => _choose(context),
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
        child: RowChip(
          // The tap is counted by the Listener; this only shows the ripple.
          onPressed: () {},
          // Coloured: the one chip of the row that is a button to press.
          filled: true,
          label: Text(
            'TAP',
            style: rowChipStyle(
              context,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            )?.copyWith(letterSpacing: 1),
          ),
        ),
      ),
    );
  }
}
