import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/theme.dart';
import 'package:low_end/widgets/choice_menu.dart';

void main() {
  testWidgets('the chosen line has no square band, only accent and tick', (
    tester,
  ) async {
    final theme = LowEndTheme.dark;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (field) => TextButton(
                onPressed: () => showChoiceMenu(
                  anchor: field,
                  selected: 1,
                  choices: const [
                    Choice(value: 0, title: 'Zero'),
                    Choice(value: 1, title: 'One'),
                    Choice(value: 2, title: 'Two'),
                  ],
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    final fieldBottom = tester.getBottomLeft(find.text('Open')).dy;
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // No grey band behind the chosen line.
    final bands = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((b) => b.color == theme.highlightColor);
    expect(bands, isEmpty);
    expect(find.byIcon(Icons.check), findsOneWidget);
    // The menu opens under the field with its first line first, not moved
    // up to put the chosen line there.
    expect(tester.getTopLeft(find.text('Zero')).dy, greaterThan(fieldBottom));
    // Its lines are clipped to its round corners.
    final menu = tester.widget<Material>(
      find
          .ancestor(of: find.text('Zero'), matching: find.byType(Material))
          .last,
    );
    expect(menu.clipBehavior, Clip.antiAlias);
  });
}
