import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The round dial at the heart of every section: the strobe of the tuner,
/// the circle of fifths of the drone, the beats of the metronome. One
/// geometry and one place on screen for all three, so moving between tabs
/// the circle stays put and only what is drawn in it changes.
class DialGeometry {
  DialGeometry(Size size)
    : center = size.center(Offset.zero),
      radius = size.shortestSide / 2;

  final Offset center;

  /// Radius of the whole dial, its background disc.
  final double radius;

  /// The ring where each section draws its segments, between [ringInner]
  /// and [ringOuter].
  double get ringOuter => radius * 0.97;
  double get ringInner => radius * 0.64;

  /// The plain centre, where the note or the beat dot goes.
  double get hub => radius * 0.61;

  /// The gap left between neighbouring segments, in radians.
  static const gap = 0.05;

  /// Paints the background disc and the hub.
  void paintBase(Canvas canvas, {required Color disc, required Color hub}) {
    canvas.drawCircle(center, radius, Paint()..color = disc);
    canvas.drawCircle(center, this.hub, Paint()..color = hub);
  }

  /// Paints one ring segment from [startAngle] (0 is the top, clockwise)
  /// across [sweep] radians, between radii [inner] and [outer] (the whole
  /// ring by default).
  void paintSegment(
    Canvas canvas, {
    required double startAngle,
    required double sweep,
    required Color color,
    double? inner,
    double? outer,
    double? stroke,
  }) {
    final rIn = inner ?? ringInner, rOut = outer ?? ringOuter;
    final start = startAngle - math.pi / 2;
    final path = Path()
      ..arcTo(Rect.fromCircle(center: center, radius: rOut), start, sweep, true)
      ..arcTo(
        Rect.fromCircle(center: center, radius: rIn),
        start + sweep,
        -sweep,
        false,
      )
      ..close();
    final paint = Paint()..color = color;
    // With a [stroke] width, only the outline.
    if (stroke != null) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round;
    }
    canvas.drawPath(path, paint);
  }

  /// A point at [radius] from the centre, at [angle] (0 is the top,
  /// clockwise).
  Offset pointAt(double angle, double radius) =>
      center + Offset(math.sin(angle), -math.cos(angle)) * radius;

  /// Where the middle of a segment centred on [angle] sits (0 is the top,
  /// clockwise).
  Offset ringPoint(double angle) {
    final r = (ringInner + ringOuter) / 2;
    return center + Offset(math.sin(angle), -math.cos(angle)) * r;
  }

  /// Thickness of the ring.
  double get ringWidth => ringOuter - ringInner;
}

/// Lays out a section around its dial, the same way on every tab: the dial
/// at the top, then two rows of controls, each the same height and in the
/// same place whatever the section, so moving between tabs only what is
/// inside them changes.
class DialLayout extends StatelessWidget {
  const DialLayout({
    super.key,
    required this.dial,
    required this.upper,
    required this.lower,
    required this.footer,
  });

  final Widget dial;

  /// The first row under the dial: the tempo, Root or Chord, the tuner's
  /// messages.
  final Widget upper;

  /// The second row: TAP, the chord, Pause.
  final Widget lower;

  /// The third row: the metronome / drone balance, or the reference A on
  /// the tuner.
  final Widget footer;

  /// Largest dial, on tablets.
  static const _maxSize = 420.0;

  /// Minimum heights of the two rows, and the room they take with their
  /// spacing; with large text a row grows and the screen scrolls.
  static const upperHeight = 88.0;
  static const lowerHeight = 64.0;
  static const footerHeight = 56.0;
  static const _controlsRoom = upperHeight + lowerHeight + footerHeight + 88;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.max(
          200.0,
          math.min(
            math.min(constraints.maxWidth - 32, _maxSize),
            constraints.maxHeight - _controlsRoom,
          ),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            // The dial and the rows are centred in the height as one block,
            // the same on every tab (the rows keep fixed heights), and the
            // screen scrolls when they do not fit (very large text).
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 32),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(dimension: size, child: dial),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: upperHeight,
                    maxWidth: _maxSize,
                  ),
                  child: Center(child: upper),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: lowerHeight,
                    maxWidth: _maxSize,
                  ),
                  child: Center(child: lower),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: footerHeight,
                    maxWidth: _maxSize,
                  ),
                  child: Center(child: footer),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
