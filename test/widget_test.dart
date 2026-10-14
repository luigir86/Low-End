import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/widgets/pulsing_dot.dart';

void main() {
  testWidgets('shows the two main sections and switches between them', (
    tester,
  ) async {
    await tester.pumpWidget(LowEndApp(toneOutput: SilentToneOutput()));
    await tester.pumpAndSettle();

    expect(find.text('Tuner'), findsOneWidget);
    expect(find.text('Metronome'), findsOneWidget);
    expect(find.text('Library'), findsNothing);

    await tester.tap(find.text('Metronome'));
    await tester.pumpAndSettle();
    expect(
      find.text('Precise metronome with accents and subdivisions.'),
      findsOneWidget,
    );
  });

  testWidgets('drone shows in the bar while playing and stops from there', (
    tester,
  ) async {
    final output = SilentToneOutput();
    await tester.pumpWidget(LowEndApp(toneOutput: output));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Drone').first);
    await tester.pumpAndSettle();
    expect(find.byType(PulsingDot), findsNothing);

    await tester.tap(find.text('Play'));
    // The strip slides in; pumpAndSettle would wait forever on the pulsing dot.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(output.frequencies, isNotEmpty);
    // One dot on the tab icon, one in the now-playing strip.
    expect(find.byType(PulsingDot), findsNWidgets(2));
    expect(find.byTooltip('Stop Drone · A3'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop Drone · A3'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(output.frequencies, isEmpty);
    expect(find.byType(PulsingDot), findsNothing);
  });

  testWidgets('drone can be started from the metronome', (tester) async {
    final output = SilentToneOutput();
    await tester.pumpWidget(LowEndApp(toneOutput: output));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metronome'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play Drone · A3'));
    await tester.pump();
    expect(output.frequencies, isNotEmpty);
    // On the shortcut itself and in the now-playing strip.
    expect(find.byTooltip('Stop Drone · A3'), findsNWidgets(2));
  });

  testWidgets('the About dialog shows the licence and the package notices', (
    tester,
  ) async {
    await tester.pumpWidget(LowEndApp(toneOutput: SilentToneOutput()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('About Low End'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Free and open-source software, released under the MIT License.',
      ),
      findsOneWidget,
    );
    expect(find.text('View licenses'), findsOneWidget);
  });
}
