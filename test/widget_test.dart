import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/audio/mic_input.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/widgets/pulsing_dot.dart';

void main() {
  testWidgets('shows the three main sections and switches between them', (
    tester,
  ) async {
    await tester.pumpWidget(
      LowEndApp(toneOutput: SilentToneOutput(), micInput: FakeMicInput()),
    );
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

  testWidgets('a drone key plays, shows on the other tabs and stops', (
    tester,
  ) async {
    final output = SilentToneOutput();
    await tester.pumpWidget(
      LowEndApp(toneOutput: output, micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Drone'));
    await tester.pumpAndSettle();
    expect(find.byType(PulsingDot), findsNothing);

    await tester.tap(find.text('A'));
    // pumpAndSettle would wait forever on the pulsing dot.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(output.frequencies.single, closeTo(440, 0.01));
    // The dot on the tab icon; on its own tab the lit key says the rest.
    expect(find.byType(PulsingDot), findsOneWidget);

    // Elsewhere, the strip above the tabs can stop it.
    await tester.tap(find.text('Tuner'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PulsingDot), findsNWidgets(2));
    await tester.tap(find.byTooltip('Stop Drone · A4'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(output.frequencies, isEmpty);
    expect(find.byType(PulsingDot), findsNothing);
  });

  testWidgets('drone can be started from the metronome', (tester) async {
    final output = SilentToneOutput();
    await tester.pumpWidget(
      LowEndApp(toneOutput: output, micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metronome'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play Drone · A4'));
    await tester.pump();
    expect(output.frequencies, isNotEmpty);
    // On the shortcut only: the Metronome tab hides the now-playing strip,
    // since the shortcut card already shows the drone.
    expect(find.byTooltip('Stop Drone · A4'), findsOneWidget);
    // Back on the tuner, the strip offers to stop it.
    await tester.tap(find.text('Tuner'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('Stop Drone · A4'), findsOneWidget);
  });

  testWidgets('settings change the language, note names and reference A', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final output = SilentToneOutput();
    await tester.pumpWidget(
      LowEndApp(toneOutput: output, micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Italiano'));
    await tester.pumpAndSettle();
    expect(find.text('Impostazioni'), findsOneWidget);
    expect(find.text('La di riferimento'), findsOneWidget);

    await tester.tap(find.text('C D E (A4 = 440 Hz)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('440 Hz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('442 Hz').last);
    await tester.pumpAndSettle();

    // The app is in Italian now, so the back button says "Indietro".
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drone'));
    await tester.pumpAndSettle();
    // Italian app, but letter names as chosen; the drone follows 442 Hz.
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(output.frequencies.single, closeTo(442, 0.01));
    expect(find.text('Fondamentale'), findsWidgets);
  });

  testWidgets('the About dialog shows the licence and the package notices', (
    tester,
  ) async {
    await tester.pumpWidget(
      LowEndApp(toneOutput: SilentToneOutput(), micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('About Low End'), 100);
    await tester.tap(find.text('About Low End'));
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
