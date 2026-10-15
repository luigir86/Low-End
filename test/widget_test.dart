import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/audio/click_output.dart';
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
    expect(find.text('Drone'), findsOneWidget);
    expect(find.text('Metronome'), findsOneWidget);
    expect(find.text('Library'), findsNothing);

    await tester.tap(find.text('Metronome'));
    await tester.pumpAndSettle();
    expect(find.text('Tap to start'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
    expect(find.text('TAP'), findsOneWidget);
  });

  testWidgets('drone and metronome play together, pause on the tuner and '
      'carry on after', (tester) async {
    final tone = SilentToneOutput();
    final click = SilentClickOutput();
    final mic = FakeMicInput();
    await tester.pumpWidget(
      LowEndApp(toneOutput: tone, clickOutput: click, micInput: mic),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Drone'));
    await tester.pumpAndSettle();
    expect(find.byType(PulsingDot), findsNothing);
    await tester.tap(find.text('A'));
    // pumpAndSettle would wait forever on the pulsing dots.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies.single, closeTo(440, 0.01));

    await tester.tap(find.text('Metronome'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Tap to start'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(click.bar, isNotNull);
    // A dot on each playing tab, and no strip to stop them from elsewhere.
    expect(find.byType(PulsingDot), findsNWidgets(2));
    expect(find.byTooltip('Stop Drone · A4'), findsNothing);

    // The tuner pauses both, so the microphone hears only the bass.
    await tester.tap(find.text('Tuner'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies, isEmpty);
    expect(click.bar, isNull);
    expect(mic.isCapturing, isTrue);
    expect(find.byType(PulsingDot), findsNothing);

    // Leaving it, they carry on.
    await tester.tap(find.text('Drone'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies.single, closeTo(440, 0.01));
    expect(click.bar, isNotNull);
    expect(mic.isCapturing, isFalse);
    expect(find.byType(PulsingDot), findsNWidgets(2));
  });

  testWidgets(
    'the metronome starts and stops from the ring, with − + and TAP',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      final click = SilentClickOutput();
      await tester.pumpWidget(
        LowEndApp(
          toneOutput: SilentToneOutput(),
          clickOutput: click,
          micInput: FakeMicInput(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Metronome'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Faster'));
      await tester.tap(find.byTooltip('Faster'));
      await tester.tap(find.byTooltip('Slower'));
      await tester.pump();
      expect(find.text('81'), findsOneWidget);

      await tester.tap(find.text('Tap to start'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(click.bar, isNotNull);
      expect(find.text('Tap to start'), findsNothing);

      // The tempo maths of TAP are checked in metronome_controller_test.dart
      // (a widget test's fake clock does not move a real Stopwatch).
      await tester.tap(find.text('TAP'));
      await tester.pump();

      // Touching the ring again stops it.
      await tester.tap(find.bySemanticsLabel('Stop the metronome'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(click.bar, isNull);
    },
  );

  testWidgets('touching the middle of the drone dial stops and restarts it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final tone = SilentToneOutput();
    await tester.pumpWidget(
      LowEndApp(toneOutput: tone, micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('D'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies, isNotEmpty);

    await tester.tap(find.bySemanticsLabel(RegExp('^Stop the drone')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies, isEmpty);

    // Again: the last note plays again.
    await tester.tap(find.bySemanticsLabel(RegExp('^Play D')).last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies.single, closeTo(293.66, 0.01));
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
