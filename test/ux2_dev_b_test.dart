import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/home_shell.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/app/settings.dart';
import 'package:low_end/audio/audio_scope.dart';
import 'package:low_end/audio/mic_input.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/features/tuner/drone/drone_controller.dart';
import 'package:low_end/features/tuner/drone/harmony.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AudioScope> _launch(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  bool portrait = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'seen_guide': true,
    'seen_swipe_hint': true,
    ...prefs,
  });
  if (portrait) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    LowEndApp(
      toneOutput: SilentToneOutput(),
      micInput: FakeMicInput(),
      settings: await AppSettings.load(),
    ),
  );
  await tester.pumpAndSettle();
  return AudioScope.of(tester.element(find.byType(HomeShell)));
}

void main() {
  testWidgets('the tempo keeps its name when stopped', (tester) async {
    await _launch(tester, portrait: true);
    expect(find.text('♩ Andante'), findsOneWidget);
    expect(find.text('Tap to start'), findsOneWidget);
  });

  testWidgets(
    'tapping the current tab changes nothing: a tab only goes to its section',
    (tester) async {
      final scope = await _launch(tester, portrait: true);
      scope.metronome.start();
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Metronome'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(scope.metronome.isPlaying, isTrue);
      scope.metronome.stop();
    },
  );

  testWidgets('the key is written out and a numeral says its degree', (
    tester,
  ) async {
    final scope = await _launch(tester, portrait: true);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Harmony'),
      ),
    );
    await tester.pumpAndSettle();
    scope.drone
      ..setPitchClass(9)
      ..setVoicing(DroneVoicing.progression);
    await tester.pumpAndSettle();
    expect(find.text('II–V–I in A major'), findsOneWidget);

    await tester.tap(find.text('II'));
    await tester.pumpAndSettle();
    expect(find.text('Key: A major'), findsOneWidget);
    expect(find.text('Supertonic'), findsOneWidget);
    expect(find.text('Bm7'), findsOneWidget);
    expect(find.text('Legend'), findsOneWidget);
  });

  testWidgets('an example song sets key, progression and tempo', (
    tester,
  ) async {
    final scope = await _launch(tester, portrait: true);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Harmony'),
      ),
    );
    await tester.pumpAndSettle();
    // The songs are in the sound options.
    await tester.tap(find.byTooltip('Sound options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Example songs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue Bossa'));
    await tester.pumpAndSettle();
    expect(scope.drone.voicing, DroneVoicing.progression);
    expect(scope.drone.progression, Progression.minorTwoFiveOne);
    expect(scope.drone.note.pitchClass, 0);
    expect(scope.metronome.bpm, 140);
  });

  test('every example song has a name, a key and a sensible tempo', () {
    expect(exampleSongs, isNotEmpty);
    for (final s in exampleSongs) {
      expect(s.title, isNotEmpty);
      expect(s.pitchClass, inInclusiveRange(0, 11));
      expect(s.bpm, inInclusiveRange(60, 200));
    }
    // Keyed to natural notes: no spelling to choose.
    expect(
      exampleSongs.map((s) => s.pitchClass).toSet().intersection({
        1,
        3,
        6,
        8,
        10,
      }),
      isEmpty,
    );
  });
}
