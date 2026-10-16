import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app's mark: the scroll at the head of a double bass, a neck rising
/// into a spiral that curls in on itself, with a warm glow behind it.
///
/// Drawn in code so that the launcher icon (see tool/make_icons.dart), the
/// About dialog and anything else share one shape.
class ScrollMarkPainter extends CustomPainter {
  const ScrollMarkPainter({
    this.light = const Color(0xFFE9CDB6),
    this.brass = const Color(0xFFD9A05B),
    this.glow = true,
    this.flat = false,
  });

  /// The wood side of the gradient on the scroll.
  final Color light;

  /// The warm end of the gradient, and the eye of the scroll.
  final Color brass;

  /// A soft warm light behind the scroll.
  final bool glow;

  /// One flat colour ([light]) with no gradient or glow, for the themed
  /// (monochrome) launcher icon.
  final bool flat;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    // The scroll fits a box of 0.62 s, centred, to keep inside the safe
    // area of an adaptive icon.
    final centre = Offset(s * 0.53, s * 0.42);
    final outer = s * 0.215;
    final thick = s * 0.085;
    if (glow && !flat) {
      canvas.drawCircle(
        centre,
        s * 0.42,
        Paint()
          ..shader = RadialGradient(
            colors: [brass.withValues(alpha: 0.35), brass.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: centre, radius: s * 0.42)),
      );
    }

    // The spiral: from the left of the centre, over the top and round,
    // closing in, and thinning as it goes.
    const turns = 1.3;
    const steps = 160;
    final left = <Offset>[], right = <Offset>[];
    Offset point(double t) {
      final angle = math.pi + 2 * math.pi * turns * t;
      final r = outer * (1 - 0.82 * t);
      return centre + Offset(math.cos(angle), math.sin(angle)) * r;
    }

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final p = point(t), ahead = point(math.min(1, t + 0.002));
      final back = point(math.max(0, t - 0.002));
      final d = ahead - back;
      final n = Offset(-d.dy, d.dx) / d.distance;
      final w = thick * (1 - 0.55 * t) / 2;
      left.add(p + n * w);
      right.add(p - n * w);
    }
    final start = point(0);
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    // The neck, straight down from where the spiral starts.
    final neck = RRect.fromLTRBR(
      start.dx - thick / 2,
      start.dy - thick * 0.4,
      start.dx + thick / 2,
      s * 0.80,
      Radius.circular(thick * 0.18),
    );
    final shape = Path.combine(
      PathOperation.union,
      path,
      Path()..addRRect(neck),
    );

    final bounds = Rect.fromLTWH(0, s * 0.15, s, s * 0.8);
    final paint = Paint()
      ..shader = flat
          ? null
          : LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [light, brass],
            ).createShader(bounds)
      ..color = light;
    canvas.drawPath(shape, paint);

    // The eye at the heart of the spiral.
    final eye = point(1);
    canvas.drawCircle(eye, thick * 0.62, Paint()..color = flat ? light : brass);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ScrollMarkPainter old) =>
      old.light != light ||
      old.brass != brass ||
      old.glow != glow ||
      old.flat != flat;
}
