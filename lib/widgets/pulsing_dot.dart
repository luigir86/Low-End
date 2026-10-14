import 'package:flutter/material.dart';

/// Small dot that pulses gently, shown on a tab whose section is playing.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, this.size = 8});

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
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// [icon] with a [PulsingDot] in its top-right corner when [active].
class ActivityIcon extends StatelessWidget {
  const ActivityIcon({super.key, required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (active) const Positioned(top: -2, right: -4, child: PulsingDot()),
      ],
    );
  }
}
