import 'package:flutter/material.dart';

/// The pill of a row under the dial: two halves (Chromatic / instrument on
/// the tuner, time signature / subdivision on the metronome), or three with a
/// [middle] one (metronome / both / harmony): 40 dp high to the eye, 48 dp to
/// touch. A part that is [leftFilled], [middleFilled] or [rightFilled] is the
/// chosen one. The parts are what is touched, built with [PillSwitch.half],
/// [PillSwitch.middleHalf] and [PillSwitch.label].
class PillSwitch extends StatelessWidget {
  const PillSwitch({
    super.key,
    required this.leftFilled,
    required this.rightFilled,
    required this.left,
    required this.right,
    this.middle,
    this.middleFilled = false,
  });

  final bool leftFilled;
  final bool rightFilled;
  final bool middleFilled;
  final Widget left;
  final Widget right;

  /// The part between the two, if there is one.
  final Widget? middle;

  /// A half, touchable over its 48 dp with its ink kept inside the pill.
  static Widget half({required bool left, required Widget child}) =>
      _PillHalf(left: left, child: child);

  /// The part between the halves of a three-part pill: square, with its ink
  /// kept inside the pill.
  static Widget middleHalf({required Widget child}) =>
      _PillHalf(left: null, child: child);

  /// The words of a half, shrinking to fit, in the colour of its state.
  static Widget label(BuildContext context, bool selected, Widget child) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: DefaultTextStyle.merge(
        style: theme.textTheme.labelLarge?.copyWith(
          color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color fill(bool filled) =>
        filled ? scheme.primaryContainer : Colors.transparent;
    return Semantics(
      container: true,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Stack(
          children: [
            // What is seen: the pill, with the chosen part filled.
            Center(
              child: SizedBox(
                height: 40,
                child: Material(
                  type: MaterialType.transparency,
                  shape: StadiumBorder(side: BorderSide(color: scheme.outline)),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: ColoredBox(color: fill(leftFilled))),
                      VerticalDivider(width: 1, color: scheme.outline),
                      if (middle != null) ...[
                        Expanded(child: ColoredBox(color: fill(middleFilled))),
                        VerticalDivider(width: 1, color: scheme.outline),
                      ],
                      Expanded(child: ColoredBox(color: fill(rightFilled))),
                    ],
                  ),
                ),
              ),
            ),
            // What is touched: the parts, as high as a finger.
            Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 1),
                  if (middle != null) ...[
                    Expanded(child: middle!),
                    const SizedBox(width: 1),
                  ],
                  Expanded(child: right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One part of the switch, touchable over its 48 dp but with its ink
/// (press, hover, focus) kept inside the 40 dp pill, with the rounded outer
/// corners and the flat inner side of the half it is (a middle part has no
/// rounded corner).
class _PillHalf extends StatelessWidget {
  const _PillHalf({required this.left, required this.child});

  /// True for the left half, false for the right, null for a middle part.
  final bool? left;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: _PillHalfClipper(left),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class _PillHalfClipper extends CustomClipper<Path> {
  const _PillHalfClipper(this.left);

  final bool? left;

  static const _height = 40.0;

  @override
  Path getClip(Size size) {
    const round = Radius.circular(_height / 2);
    final top = (size.height - _height) / 2;
    return Path()..addRRect(
      RRect.fromLTRBAndCorners(
        0,
        top,
        size.width,
        top + _height,
        topLeft: left == true ? round : Radius.zero,
        bottomLeft: left == true ? round : Radius.zero,
        topRight: left == false ? round : Radius.zero,
        bottomRight: left == false ? round : Radius.zero,
      ),
    );
  }

  @override
  bool shouldReclip(_PillHalfClipper old) => old.left != left;
}
