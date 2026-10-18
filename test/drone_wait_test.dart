import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/home_shell.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/audio/audio_scope.dart';
import 'package:low_end/audio/click_output.dart';
import 'package:low_end/audio/mic_input.dart';
import 'package:low_end/audio/piano_output.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/features/tuner/drone/drone_controller.dart';

void main() {
  test('counts down the wait for the metronome\'s bar line', () async {
    final piano = SilentPianoOutput();
    final drone = DroneController(SilentToneOutput(), piano: piano);
    drone.setVoicing(DroneVoicing.chord);
    await drone.start();
    // Nothing to wait for: the piano came in at once.
    expect(drone.waitLeft, isNull);
    await drone.stop();
    expect(drone.waitLeft, isNull);

    piano.delay = const Duration(seconds: 2);
    await drone.start();
    final left = drone.waitLeft!;
    expect(left, greaterThan(const Duration(milliseconds: 1500)));
    expect(left, lessThanOrEqualTo(const Duration(seconds: 2)));
    await drone.stop();
    expect(drone.waitLeft, isNull);
  });

  testWidgets('the hub shows the seconds to go', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final piano = SilentPianoOutput()..delay = const Duration(seconds: 3);
    await tester.pumpWidget(
      LowEndApp(
        toneOutput: SilentToneOutput(),
        clickOutput: SilentClickOutput(),
        pianoOutput: piano,
        micInput: FakeMicInput(),
      ),
    );
    await tester.pumpAndSettle();
    final scope = AudioScope.of(tester.element(find.byType(HomeShell)));
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Harmony'),
      ),
    );
    await tester.pumpAndSettle();
    await scope.drone.start();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('A4'), findsNothing);

    // Stopped, the hub goes back to its hint.
    await scope.drone.stop();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('3'), findsNothing);
  });
}
