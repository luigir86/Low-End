import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme.dart';
import '../../audio/audio_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dial.dart';
import '../../widgets/pill_switch.dart';
import '../../widgets/row_controls.dart';
import 'metronome_controller.dart';
import 'note_icon.dart';
import 'subdivision.dart';
import 'tempo_dialog.dart';
import 'time_signature.dart';

/// The metronome: a ring with one segment per beat of the bar (4 in 4/4,
/// 6 in 6/8, and so on) lights up clockwise from 12 o'clock, with the "one"
/// in its own colour, and the tempo in the middle. In bars felt in groups
/// (6/8) wider gaps split the groups, and a bar of one beat is a single
/// segment that flashes. Touching the ring starts and stops it; below it, a
/// row like the harmony's that chooses the bar (the time signature and what
/// fills each beat), and one for the tempo: TAP, − + and a pencil to type it.
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
        // The first row, a pill like the tuner's, chooses the bar: the time
        // signature and what fills each beat. The second only sets the tempo:
        // TAP, − + and the pencil.
        upper: PillSwitch(
          key: const Key('barSwitch'),
          leftFilled: false,
          rightFilled: false,
          left: _SignatureButton(metronome: metronome),
          right: _SubdivisionField(metronome: metronome),
        ),
        lower: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _TapButton(metronome: metronome)),
                const SizedBox(width: 6),
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
          '${beatUnitName(l10n, metronome.signature.beatUnit)}, '
          '${tempoMark(metronome.signature, metronome.bpm)}',
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
      } else if (metronome.isSilent(b)) {
        // A beat left silent (1 and 3, with the click on 2 and 4) only
        // glows: the place in the bar is still seen.
        color = colors.outline.withValues(alpha: 0.35);
      } else if (b == 0) {
        color = downbeat;
      } else if (signature.grouped && !opens) {
        // The weak pulses of a group are softer than its first.
        color = colors.outline.withValues(alpha: 0.6);
      } else {
        // A step softer than the "one", which is the accent itself.
        color = colors.outline;
      }
      // The lit "one" is also wider, into the ring's margins: it stands out
      // by its shape as well as by its colour.
      final one = b == 0 && b == beat && count > 1 && !metronome.isSilent(0);
      dial.paintSegment(
        canvas,
        inner: dial.ringInner + dial.ringWidth * (one ? 0.12 : 0.22),
        outer: dial.ringOuter - dial.ringWidth * (one ? 0.0 : 0.08),
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
        // What touching does, or the figure the tempo counts and its name:
        // "♩ Andante", "♩. Allegro · ♪ = 180" in 6/8.
        if (!waiting) ...[
          Text(
            tempoUnitCaption(metronome.signature, metronome.bpm),
            textAlign: TextAlign.center,
            // A little taller than the text: the note symbol comes from
            // another font and was clipped at the top.
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          // Stopped: the tempo keeps its name, and under it what touching
          // does.
          if (!playing)
            Text(
              l10n.metronomeHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ],
    );
  }
}

/// What the tempo counts and how fast it is, under its number: "♩ Andante",
/// "♪ Allegro" in 7/8 and in the compound bars "♩. Allegro · ♪ = 180", the
/// eighths too.
String tempoUnitCaption(TimeSignature signature, int bpm) {
  final caption = '${signature.beatUnit.symbol} ${tempoMark(signature, bpm)}';
  if (!signature.compound) return caption;
  return '$caption · ${BeatUnit.eighth.symbol} = '
      '${bpm * signature.pulsesPerBeat}';
}

/// The Italian name of the tempo, the same in every language, for [bpm]
/// counted in the beat of [signature]. The limits are in quarter notes per
/// minute, so a dotted quarter or an eighth is first turned into quarters.
String tempoMark(TimeSignature signature, int bpm) {
  final quarters = switch (signature.beatUnit) {
    BeatUnit.quarter => bpm.toDouble(),
    BeatUnit.dottedQuarter => bpm * 1.5,
    BeatUnit.eighth => bpm / 2,
  };
  const limits = [
    (40, 'Grave'),
    (60, 'Largo'),
    (66, 'Larghetto'),
    (76, 'Adagio'),
    (108, 'Andante'),
    (120, 'Moderato'),
    (156, 'Allegro'),
    (176, 'Vivace'),
    (200, 'Presto'),
  ];
  for (final (limit, name) in limits) {
    if (quarters < limit) return name;
  }
  return 'Prestissimo';
}

/// The figure the tempo counts, for screen readers.
String beatUnitName(AppLocalizations l10n, BeatUnit unit) => switch (unit) {
  BeatUnit.quarter => l10n.beatUnitQuarter,
  BeatUnit.dottedQuarter => l10n.beatUnitDottedQuarter,
  BeatUnit.eighth => l10n.beatUnitEighth,
};

/// What fills each beat, the right half of the pill: a quarter note, two
/// eighths, a triplet, four sixteenths, or the swung eighths and sixteenths
/// (softer clicks between the beats). It shows the notes and opens a menu of
/// them. Bars counted in eighths are always played plain, so it is off there.
class _SubdivisionField extends StatelessWidget {
  const _SubdivisionField({required this.metronome});

  final MetronomeController metronome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subdivision = metronome.subdivision;
    final enabled = metronome.subdivisionApplies;
    return PillSwitch.half(
      left: false,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: l10n.subdivisionLabel,
        value: subdivisionName(l10n, subdivision),
        excludeSemantics: true,
        onTap: enabled ? () => _choose(context) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.38,
          child: InkWell(
            key: const Key('subdivisionMenu'),
            onTap: enabled ? () => _choose(context) : null,
            child: PillSwitch.label(
              context,
              false,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NoteIcon(subdivision, height: 26),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The menu, opened over the field.
  Future<void> _choose(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final picked = await showMenu<Subdivision>(
      context: context,
      position: position,
      initialValue: metronome.subdivision,
      items: [
        for (final s in Subdivision.values)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: NoteIcon(s, height: 26),
                  ),
                ),
                Flexible(
                  child: Text(
                    subdivisionName(l10n, s),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    if (picked != null) metronome.setSubdivision(picked);
  }
}

/// What fills the beat, for the menu and for screen readers.
String subdivisionName(AppLocalizations l10n, Subdivision s) => switch (s) {
  Subdivision.quarters => l10n.subdivisionQuarters,
  Subdivision.eighths => l10n.subdivisionEighths,
  Subdivision.swungEighths => l10n.subdivisionSwungEighths,
  Subdivision.triplets => l10n.subdivisionTriplets,
  Subdivision.sixteenths => l10n.subdivisionSixteenths,
  Subdivision.swungSixteenths => l10n.subdivisionSwungSixteenths,
};

/// A chip of the − + pair that steps by one when tapped. Held, it keeps
/// going by one, faster and faster, and after a couple of seconds by fives
/// (to the next multiple of 5), until it is let go.
class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onStep,
    required this.onHold,
  });

  final IconData icon;

  /// What a screen reader says: there is no tooltip, since holding the
  /// chip is how the tempo runs.
  final String tooltip;
  final VoidCallback? onStep;

  /// Called again and again while held, with the size of the step.
  final void Function(int unit) onHold;

  /// How long a touch lasts before it counts as held.
  static const holdAfter = Duration(milliseconds: 400);

  /// The pause between the first steps of a hold, and the shortest one it
  /// shrinks to.
  static const _firstEvery = 200;
  static const _fastestEvery = 50;

  /// How long the steps of 1 last before they become steps of 5.
  static const _fivesAfter = Duration(milliseconds: 2400);
  static const _fivesEvery = Duration(milliseconds: 140);

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _timer;

  /// How long the hold has been running, as the sum of its steps' pauses.
  var _held = Duration.zero;
  var _every = _StepButton._firstEvery.toDouble();

  /// True once the touch has turned into a hold: letting go then must not
  /// also count as a tap.
  var _holding = false;

  void _down() {
    _stop();
    _holding = false;
    if (widget.onStep == null) return;
    _timer = Timer(_StepButton.holdAfter, () {
      _holding = true;
      _every = _StepButton._firstEvery.toDouble();
      _held = Duration.zero;
      _tick();
    });
  }

  void _tick() {
    if (!mounted || widget.onStep == null) return _stop();
    final Duration next;
    if (_held < _StepButton._fivesAfter) {
      widget.onHold(1);
      next = Duration(milliseconds: _every.round());
      // Each step comes a little sooner than the last.
      _every = math.max(_StepButton._fastestEvery.toDouble(), _every * 0.85);
    } else {
      widget.onHold(5);
      next = _StepButton._fivesEvery;
    }
    _held += next;
    _timer = Timer(next, _tick);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onStep = widget.onStep;
    return Semantics(
      button: true,
      enabled: onStep != null,
      label: widget.tooltip,
      onTap: onStep,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => _down(),
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) {
          _stop();
          _holding = false;
        },
        child: RowChip(
          label: Icon(widget.icon, size: 24),
          // A tap steps by one; the end of a hold has already stepped.
          onPressed: onStep == null
              ? null
              : () {
                  if (_holding) {
                    _holding = false;
                    return;
                  }
                  onStep();
                },
        ),
      ),
    );
  }
}

/// The left half of the pill: shows the time signature and opens the list to
/// choose another.
class _SignatureButton extends StatelessWidget {
  const _SignatureButton({required this.metronome});

  final MetronomeController metronome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final signature = metronome.signature;
    // With the click on 2 and 4 the half says so: "4/4 · 2 & 4".
    final value = metronome.backbeat && metronome.backbeatApplies
        ? '${signature.label} · ${l10n.backbeatShort}'
        : signature.label;
    return PillSwitch.half(
      left: true,
      child: Semantics(
        button: true,
        label: l10n.timeSignature,
        value: value,
        excludeSemantics: true,
        onTap: () => _choose(context),
        child: InkWell(
          key: const Key('signatureMenu'),
          onTap: () => _choose(context),
          child: PillSwitch.label(
            context,
            false,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, maxLines: 1),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
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
              const Divider(),
              // Kept whatever the bar, and heard in 2/4 and 4/4.
              ListenableBuilder(
                listenable: metronome,
                builder: (context, _) => SwitchListTile(
                  key: const Key('backbeatSwitch'),
                  value: metronome.backbeat,
                  onChanged: metronome.setBackbeat,
                  title: Text(l10n.backbeatTitle),
                  subtitle: Text(l10n.backbeatSubtitle),
                ),
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
        // As wide as the room it is given (half the row): the chip itself
        // only takes the width of its label.
        child: LayoutBuilder(
          builder: (context, box) => RowChip(
            // The tap is counted by the Listener; this only shows the ripple.
            onPressed: () {},
            // Coloured: the one chip of the row that is a button to press.
            filled: true,
            label: SizedBox(
              // Less the chip's own padding and border.
              width: math.max(0, box.maxWidth - 28),
              child: Center(
                child: Text(
                  'TAP',
                  style: rowChipStyle(
                    context,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )?.copyWith(letterSpacing: 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
