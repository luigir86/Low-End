import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'flip_detector.dart';

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

  /// The hub as a fraction of the dial: its diameter over the dial's.
  static const hubFraction = 0.61;

  /// The plain centre, where the note or the tempo goes.
  double get hub => radius * hubFraction;

  /// The gap left between neighbouring segments, in radians.
  static const gap = 0.05;

  /// Paints the background disc and the hub.
  void paintBase(Canvas canvas, {required Color disc, required Color hub}) {
    canvas.drawCircle(center, radius, Paint()..color = disc);
    canvas.drawCircle(center, this.hub, Paint()..color = hub);
  }

  /// Width of the edge drawn round a segment that is off, see
  /// [paintSegment].
  static const offEdge = 1.5;

  /// Paints one ring segment from [startAngle] (0 is the top, clockwise)
  /// across [sweep] radians, between radii [inner] and [outer] (the whole
  /// ring by default). With a [border], an edge of that colour goes round
  /// it: a segment that is off keeps a soft fill, so that the lit ones stand
  /// out, and the edge (the theme's outline, at least 3:1 on the disc)
  /// keeps its shape visible.
  void paintSegment(
    Canvas canvas, {
    required double startAngle,
    required double sweep,
    required Color color,
    double? inner,
    double? outer,
    double? stroke,
    Color? border,
  }) {
    final rIn = inner ?? ringInner, rOut = outer ?? ringOuter;
    final start = startAngle - math.pi / 2;
    final Path path;
    if (sweep >= 2 * math.pi - 1e-6) {
      // A whole ring, with no gap (a bar of one beat): two circles.
      path = Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: center, radius: rOut))
        ..addOval(Rect.fromCircle(center: center, radius: rIn));
    } else {
      path = Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: rOut),
          start,
          sweep,
          true,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: rIn),
          start + sweep,
          -sweep,
          false,
        )
        ..close();
    }
    final paint = Paint()..color = color;
    // With a [stroke] width, only the outline.
    if (stroke != null) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round;
    }
    canvas.drawPath(path, paint);
    if (border != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = offEdge
          ..strokeJoin = StrokeJoin.round,
      );
    }
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
/// at the top, then three rows, each the same height and in the
/// same place whatever the section, so moving between tabs only what is
/// inside them changes.
class DialLayout extends StatelessWidget {
  const DialLayout({
    super.key,
    required this.dial,
    required this.upper,
    required this.lower,
    this.footer = const SizedBox.shrink(),
  });

  final Widget dial;

  /// The first row under the dial: the tempo, Root or Chord, the tuner's
  /// messages.
  final Widget upper;

  /// The second row: TAP, the chord, Pause.
  final Widget lower;

  /// The third row: the reference A on the tuner. The metronome and the
  /// harmony leave it empty, so that their rows stay where the tuner's are.
  final Widget footer;

  /// Largest dial, on tablets.
  static const _maxSize = 420.0;

  /// The height of each of the three rows, spacing included: the same for
  /// all, so that every tab is a dial and three equal rows whatever is in
  /// them (or in none, as the third of the metronome and the harmony). With
  /// large text a row grows and
  /// the screen scrolls.
  static const rowHeight = 80.0;

  /// Space between the dial and the first row.
  static const _dialGap = 16.0;
  static const _controlsRoom = 3 * rowHeight + _dialGap + 32;

  /// Landscape: the screen is wider than tall. The dial then sits on the
  /// left, next to the tab rail, and the three rows form a column on its
  /// right, at least [columnMinWidth] wide.
  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }

  static const columnMinWidth = 320.0;

  /// Marks the box of the dial, for tests.
  static const dialKey = ValueKey('dial');

  /// The smallest dial in landscape, when the screen is too narrow for both.
  static const _minLandscapeDial = 160.0;

  /// Room kept above the rows for the settings button, in the corner.
  static const _cornerRoom = 56.0;

  @override
  Widget build(BuildContext context) {
    if (isLandscape(context)) return _landscape();
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.max(
          200.0,
          math.min(
            math.min(constraints.maxWidth - 32, _maxSize),
            constraints.maxHeight - _controlsRoom,
          ),
        );
        // The room left with every row at its minimum height, shared out the
        // same on every tab, so the three dials never move between tabs and
        // stay put when a row grows (the tuner's messages): a little stays
        // under the rows for that, some goes between the dial and the rows,
        // which sit lower, nearer the thumb and with no empty band above the
        // tabs, and the rest goes above the dial.
        final block = size + _dialGap + 3 * rowHeight;
        final free = math.max(0.0, constraints.maxHeight - 32 - block);
        final slack = math.min(free * 0.2, 32.0);
        final gap = math.min(free * 0.4, 48.0);
        final top = free - slack - gap;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            // The dial and the rows sit in the same place on every tab, and
            // the screen scrolls when they do not fit (very large text).
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 32),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: top),
                SizedBox.square(key: dialKey, dimension: size, child: dial),
                SizedBox(height: _dialGap + gap),
                for (final row in [upper, lower, footer])
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: rowHeight,
                      maxWidth: _maxSize,
                    ),
                    child: Center(child: row),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _landscape() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        // Nearly the whole height, but never so wide that the column of rows
        // loses its minimum width; very narrow phones get a smaller dial.
        final size = math
            .min(
              math.min(_maxSize, height - 56),
              constraints.maxWidth - columnMinWidth - 48,
            )
            .clamp(_minLandscapeDial, _maxSize)
            .toDouble();
        // As in portrait, the rows start where the block would if it were
        // centred with every row at its minimum height, so they never move
        // between tabs; the settings button has the room above.
        final room = height - _cornerRoom - 16;
        final top = math.max(0.0, (room - 3 * rowHeight) / 2);
        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: 16),
              FlipDetector(
                child: Center(
                  child: SizedBox.square(
                    key: dialKey,
                    dimension: size,
                    child: dial,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, _cornerRoom, 16, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: math.max(0, room)),
                    child: Column(
                      children: [
                        SizedBox(height: top),
                        for (final row in [upper, lower, footer])
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: rowHeight,
                              maxWidth: _maxSize,
                            ),
                            child: Center(child: row),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
