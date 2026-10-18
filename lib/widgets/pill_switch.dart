import 'package:flutter/material.dart';

/// The two-half pill of the first row under the dial (Chromatic / instrument
/// on the tuner, Straight / Swing and the subdivision on the metronome):
/// 40 dp high to the eye, 48 dp to touch. A half that is [leftFilled] or
/// [rightFilled] is the chosen one. The halves are what is touched, built
/// with [PillSwitch.half] and [PillSwitch.label].
class PillSwitch extends StatelessWidget {
  const PillSwitch({
    super.key,
    required this.leftFilled,
    required this.rightFilled,
    required this.left,
    required this.right,
  });

  final bool leftFilled;
  final bool rightFilled;
  final Widget left;
  final Widget right;

  /// A half, touchable over its 48 dp with its ink kept inside the pill.
  static Widget half({required bool left, required Widget child}) =>
      _PillHalf(left: left, child: child);

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
            // What is seen: the pill, with the chosen half filled.
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
                      Expanded(child: ColoredBox(color: fill(rightFilled))),
                    ],
                  ),
                ),
              ),
            ),
            // What is touched: the two halves, as high as a finger.
            Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 1),
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

/// One half of the switch, touchable over its 48 dp but with its ink
/// (press, hover, focus) kept inside the 40 dp pill, with the rounded outer
/// corners and the flat inner side of the half it is.
class _PillHalf extends StatelessWidget {
  const _PillHalf({required this.left, required this.child});

  final bool left;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: _PillHalfClipper(left),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class _PillHalfClipper extends CustomClipper<Path> {
  const _PillHalfClipper(this.left);

  final bool left;

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
        topLeft: left ? round : Radius.zero,
        bottomLeft: left ? round : Radius.zero,
        topRight: left ? Radius.zero : round,
        bottomRight: left ? Radius.zero : round,
      ),
    );
  }

  @override
  bool shouldReclip(_PillHalfClipper old) => old.left != left;
}
