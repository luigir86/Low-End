import 'package:flutter/material.dart';

/// Small dot that pulses gently, shown on a tab whose section is playing.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, this.size = 11});

  final double size;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Stays still when the phone asks to remove animations.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FadeTransition(
      // Never fades far: the dot must stay easy to see.
      opacity: Tween(begin: 0.55, end: 1.0).animate(_controller),
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
        if (active) const Positioned(top: -3, right: -5, child: PulsingDot()),
      ],
    );
  }
}
