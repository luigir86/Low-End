import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/home_shell.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/app/settings.dart';
import 'package:low_end/audio/audio_scope.dart';
import 'package:low_end/audio/click_output.dart';
import 'package:low_end/audio/mic_input.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/features/metronome/feel.dart';
import 'package:low_end/features/metronome/time_signature.dart';
import 'package:low_end/features/tuner/drone/drone_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AudioScope> _pump(WidgetTester tester, AppSettings settings) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    LowEndApp(
      toneOutput: SilentToneOutput(),
      clickOutput: SilentClickOutput(),
      micInput: FakeMicInput(),
      settings: settings,
    ),
  );
  await tester.pumpAndSettle();
  return AudioScope.of(tester.element(find.byType(HomeShell)));
}

void main() {
  group('the metronome comes back as it was left', () {
    test('tempo, time signature and feel are saved and loaded', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await AppSettings.load();
      first.rememberMetronome(
        bpm: 132,
        signature: TimeSignature.sixEight,
        feel: MetronomeFeel.swing,
      );
      // Written by the time the next launch reads them.
      await Future<void>.delayed(Duration.zero);
      final second = await AppSettings.load();
      expect(second.metronomeBpm, 132);
      expect(second.metronomeSignature, TimeSignature.sixEight);
      expect(second.metronomeFeel, MetronomeFeel.swing);
    });

    test('unreadable values fall back, and the tempo stays in range', () async {
      SharedPreferences.setMockInitialValues({
        'metronome_bpm': 9999,
        'time_signature': '13/16',
        'metronome_feel': 'polka',
      });
      final s = await AppSettings.load();
      expect(s.metronomeSignature, TimeSignature.fourFour);
      expect(s.metronomeFeel, MetronomeFeel.straight);
      expect(s.metronomeBpm, 250);
      SharedPreferences.setMockInitialValues({'metronome_bpm': 'fast'});
      expect((await AppSettings.load()).metronomeBpm, 80);
    });

    testWidgets('the app opens with them and keeps what changes', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'metronome_bpm': 96,
        'time_signature': '3/4',
        'metronome_feel': 'swing',
      });
      final settings = await AppSettings.load();
      final scope = await _pump(tester, settings);
      expect(scope.metronome.bpm, 96);
      expect(scope.metronome.signature, TimeSignature.threeFour);
      expect(scope.metronome.feel, MetronomeFeel.swing);
      expect(find.text('96'), findsOneWidget);

      scope.metronome.setBpm(140);
      scope.metronome.setSignature(TimeSignature.fiveFour);
      expect(settings.metronomeBpm, 140);
      expect(settings.metronomeSignature, TimeSignature.fiveFour);
    });
  });

  testWidgets('the metronome row has the pieces of the harmony row', (
    tester,
  ) async {
    final scope = await _pump(tester, AppSettings());
    // The time signature is a bare field with "4/4" in it: no title, which
    // would not fit, but a screen reader still announces its name.
    final semantics = tester.ensureSemantics();
    expect(find.text('Time signature'), findsNothing);
    expect(find.bySemanticsLabel('Time signature'), findsOneWidget);
    semantics.dispose();
    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('TAP'), findsOneWidget);
    expect(find.byTooltip('Faster'), findsOneWidget);
    expect(find.byTooltip('Slower'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(scope.metronome.bpm, 80);
  });

  group('the reference A on the tuner', () {
    Future<AudioScope> openTuner(WidgetTester tester) async {
      final scope = await _pump(tester, AppSettings());
      await tester.tap(find.text('Tuner'));
      await tester.pumpAndSettle();
      return scope;
    }

    testWidgets('− and + step through the pitches, up to their ends', (
      tester,
    ) async {
      final scope = await openTuner(tester);
      expect(scope.settings.a4, 440);
      await tester.tap(find.byTooltip('Raise the reference A'));
      await tester.pump();
      expect(scope.settings.a4, 441);
      await tester.tap(find.byTooltip('Lower the reference A'));
      await tester.pump();
      await tester.tap(find.byTooltip('Lower the reference A'));
      await tester.pump();
      expect(scope.settings.a4, 439);
      expect(find.text('439 Hz'), findsWidgets);

      scope.settings.setReferencePitch(415);
      await tester.pump();
      // At the lowest, − is dimmed and does nothing; + still works.
      final lower = find.widgetWithIcon(ActionChip, Icons.remove);
      expect(tester.widget<ActionChip>(lower).onPressed, isNull);
      scope.settings.setReferencePitch(445);
      await tester.pump();
      final higher = find.widgetWithIcon(ActionChip, Icons.add);
      expect(tester.widget<ActionChip>(higher).onPressed, isNull);
      expect(tester.widget<ActionChip>(lower).onPressed, isNotNull);
    });

    testWidgets('the pencil offers the four standard pitches', (tester) async {
      final scope = await openTuner(tester);
      await tester.tap(find.byTooltip('Choose a standard reference A'));
      await tester.pumpAndSettle();
      for (final hz in ['415', '432', '440', '442']) {
        expect(find.text('$hz Hz'), findsWidgets);
      }
      await tester.tap(find.text('432 Hz').last);
      await tester.pumpAndSettle();
      expect(scope.settings.a4, 432);
    });
  });

  testWidgets('the circle writes the chord out, not "II of C"', (tester) async {
    final scope = await _pump(tester, AppSettings());
    await tester.tap(find.text('Harmony').last);
    await tester.pumpAndSettle();
    scope.drone.setVoicing(DroneVoicing.progression);
    await tester.pump();
    await tester.tap(find.text('C').first);
    await tester.pump();
    // II–V–I in C starts on D minor: D F A.
    expect(find.text('D F A'), findsOneWidget);
    expect(find.textContaining(' of C'), findsNothing);
    scope.drone.stop();
  });
}
