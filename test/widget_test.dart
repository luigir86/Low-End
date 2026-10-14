import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/low_end_app.dart';

void main() {
  testWidgets('shows the three main sections and switches between them',
      (tester) async {
    await tester.pumpWidget(const LowEndApp());
    await tester.pumpAndSettle();

    expect(find.text('Tuner'), findsOneWidget);
    expect(find.text('Metronome'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);

    await tester.tap(find.text('Metronome'));
    await tester.pumpAndSettle();
    expect(
      find.text('Precise metronome with accents and subdivisions.'),
      findsOneWidget,
    );
  });
}
