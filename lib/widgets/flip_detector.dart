import 'package:flutter/widgets.dart';

/// What a vertical flick does in the landscape layout: [onFlip] gets +1 for
/// the next section (the finger moved up) or -1 for the previous one.
class SectionFlip extends InheritedWidget {
  const SectionFlip({super.key, required this.onFlip, required super.child});

  final void Function(int direction) onFlip;

  static SectionFlip? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SectionFlip>();

  @override
  bool updateShouldNotify(SectionFlip old) => false;
}

/// Turns an up or down swipe on [child] into a [SectionFlip]: the landscape
/// layout has the tabs in a column, so the sections follow vertically. Only
/// the dial and the tab rail wear it, never the column of rows, which scrolls
/// with large text. A swipe that starts at the very top or bottom of the
/// screen is left to the system (notification shade, home gesture).
class FlipDetector extends StatefulWidget {
  const FlipDetector({super.key, required this.child});

  final Widget child;

  /// How far the finger must go, and the strip along the screen's top and
  /// bottom edges that is not ours.
  static const distance = 48.0;
  static const edge = 32.0;

  @override
  State<FlipDetector> createState() => _FlipDetectorState();
}

class _FlipDetectorState extends State<FlipDetector> {
  var _travel = 0.0;
  var _ignored = false;

  @override
  Widget build(BuildContext context) {
    final flip = SectionFlip.maybeOf(context);
    if (flip == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (d) {
        final height = MediaQuery.sizeOf(context).height;
        _travel = 0;
        _ignored =
            d.globalPosition.dy < FlipDetector.edge ||
            d.globalPosition.dy > height - FlipDetector.edge;
      },
      onVerticalDragUpdate: (d) {
        if (_ignored) return;
        _travel += d.delta.dy;
        if (_travel.abs() >= FlipDetector.distance) {
          // Up: the next section, like the page of a vertical PageView.
          flip.onFlip(_travel < 0 ? 1 : -1);
          _ignored = true;
        }
      },
      child: widget.child,
    );
  }
}
