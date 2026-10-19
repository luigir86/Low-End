import 'package:flutter/material.dart';

/// A row of [count] dots, the [current] one filled: the pages of the guide,
/// the chords of a progression. Only a picture; what it shows is said in
/// words beside it.
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.current,
    this.size = 10,
  });

  final int count;
  final int current;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              width: size,
              height: size,
              margin: EdgeInsets.symmetric(horizontal: size / 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == current ? colors.primary : null,
                border: Border.all(color: colors.outline, width: 1.2),
              ),
            ),
        ],
      ),
    );
  }
}
