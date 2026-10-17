import 'dart:async';

import 'package:flutter/material.dart';

/// Small dot that pulses gently, shown on a tab whose section is playing.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, this.size = 14});

  final double size;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> {
  static const _period = Duration(milliseconds: 1800);

  /// A fade this slow needs no more than a dozen steps a second: a timer
  /// instead of a vsync animation, which would redraw the whole screen 60 to
  /// 120 times a second for as long as something plays.
  static const _step = Duration(milliseconds: 80);

  final _opacity = ValueNotifier<double>(1);
  final _clock = Stopwatch();
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Stays still when the phone asks to remove animations.
    if (MediaQuery.disableAnimationsOf(context)) {
      _timer?.cancel();
      _timer = null;
      _opacity.value = 1;
    } else if (_timer == null) {
      _clock.start();
      _timer = Timer.periodic(_step, (_) {
        final phase =
            (_clock.elapsedMicroseconds % _period.inMicroseconds) /
            _period.inMicroseconds;
        // Up and down between 0.7 and 1: the dot must stay easy to see.
        final wave = phase < 0.5 ? phase * 2 : 2 - phase * 2;
        _opacity.value = 0.7 + 0.3 * Curves.linear.transform(wave);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Its own layer: a step of the pulse then costs the dot, not the bar.
    return RepaintBoundary(
      child: ValueListenableBuilder<double>(
        valueListenable: _opacity,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
            // A rim in the bar's colour sets it off from the icon below.
            border: Border.all(color: colors.surfaceContainer, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// [icon] with a [PulsingDot] in its top-right corner when [active], and
/// [activeIcon] (a filled one) in its place, if there is one.
class ActivityIcon extends StatelessWidget {
  const ActivityIcon({
    super.key,
    required this.icon,
    required this.active,
    this.activeIcon,
  });

  final IconData icon;
  final IconData? activeIcon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(active ? (activeIcon ?? icon) : icon),
        if (active) const Positioned(top: -5, right: -7, child: PulsingDot()),
      ],
    );
  }
}
