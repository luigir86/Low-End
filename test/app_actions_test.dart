import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/click_output.dart';
import 'package:low_end/features/metronome/metronome_controller.dart';
import 'package:low_end/actions/app_actions.dart';
import 'package:low_end/app/app_navigation.dart';
import 'package:low_end/app/home_shell.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/app/settings.dart';
import 'package:low_end/audio/audio_scope.dart';
import 'package:low_end/audio/mic_input.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/features/tuner/drone/drone_controller.dart';
import 'package:low_end/features/tuner/tuner_controller.dart';

void main() {
  late SilentToneOutput output;
  late FakeMicInput mic;
  late AppSettings settings;
  late AppActions actions;

  setUp(() {
    output = SilentToneOutput();
    mic = FakeMicInput();
    settings = AppSettings();
    actions = AppActions(
      drone: DroneController(output),
      metronome: MetronomeController(SilentClickOutput()),
      tuner: TunerController(mic),
      navigation: AppNavigation(),
      settings: settings,
    );
  });

  test('docs/llm-actions.json matches the action catalog', () {
    // Regenerate with: flutter test --update-goldens
    final file = File('docs/llm-actions.json');
    if (autoUpdateGoldenFiles) file.writeAsStringSync(exportActions());
    // Git on Windows may check the file out with CRLF line endings.
    final text = file.readAsStringSync().replaceAll('\r\n', '\n');
    expect(text, exportActions());
  });

  test('reads note names in English and Italian', () {
    expect(parseNote('A'), (pitchClass: 9, octave: null));
    expect(parseNote('Bb1'), (pitchClass: 10, octave: 1));
    expect(parseNote('f♯'), (pitchClass: 6, octave: null));
    expect(parseNote('Sol2'), (pitchClass: 7, octave: 2));
    expect(parseNote('sib'), (pitchClass: 10, octave: null));
    expect(parseNote('do#3'), (pitchClass: 1, octave: 3));
    expect(parseNote('H'), isNull);
  });

  test('plays and stops the drone with its settings', () async {
    final result = await actions.call('drone_play', {
      'note': 'D',
      'voicing': 'chord',
      'chord': 'minor',
    });
    expect(result['ok'], isTrue);
    final drone = (result['state']! as Map)['drone'] as Map;
    expect(drone['playing'], isTrue);
    expect(drone['note'], 'D4');
    expect(drone['voicing'], 'chord');
    expect(drone['chord'], 'minor');
    expect(output.frequencies, hasLength(3));

    await actions.call('drone_stop');
    expect(output.frequencies, isEmpty);
  });

  test('changes and reports the settings', () async {
    await actions.call('set_reference_pitch', {'hz': 438});
    final result = await actions.call('settings_set', {
      'language': 'it',
      'note_names': 'letters',
    });
    expect((result['state']! as Map)['settings'], {
      'reference_pitch_hz': 438.0,
      'language': 'it',
      'note_names': 'letters',
    });
    expect(settings.a4, 438);
    await actions.call('settings_set', {'language': 'system'});
    expect(settings.languageCode, isNull);
  });

  test('starting the tuner shows it, leaving it turns the mic off', () async {
    await actions.call('open_section', {'section': 'metronome'});
    final result = await actions.call('tuner_start');
    final state = result['state']! as Map;
    expect(state['section'], 'tuner');
    expect((state['tuner'] as Map)['status'], 'listening');
    expect(mic.isCapturing, isTrue);

    await actions.call('tuner_stop');
    expect(mic.isCapturing, isFalse);
  });

  test('explains wrong calls instead of failing', () async {
    expect(await actions.call('fly'), {
      'ok': false,
      'error': 'Unknown action "fly".',
    });
    expect(
      (await actions.call('set_reference_pitch', {'hz': 430}))['error'],
      contains('must be one of'),
    );
    expect(
      (await actions.call('drone_set', {'chord': 'ninth'}))['error'],
      contains('must be one of'),
    );
    expect(
      (await actions.call('drone_set', {'octave': 2}))['error'],
      contains('no parameter'),
    );
  });

  test('turns links into actions with typed arguments', () {
    final (name, args) = AppActions.parseLink(
      Uri.parse('lowend://action/drone_play?note=A&voicing=chord'),
    )!;
    expect(name, 'drone_play');
    expect(args, {'note': 'A', 'voicing': 'chord'});
    expect(
      AppActions.parseLink(
        Uri.parse('lowend://action/set_reference_pitch?hz=442'),
      )?.$2,
      {'hz': 442},
    );
    expect(AppActions.parseLink(Uri.parse('/tuner_stop'))?.$1, 'tuner_stop');
    expect(AppActions.parseLink(Uri.parse('/settings')), isNull);
  });

  testWidgets('a link sent to the running app starts the drone', (
    tester,
  ) async {
    final output = SilentToneOutput();
    await tester.pumpWidget(
      LowEndApp(toneOutput: output, micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePushRoute('/drone_play?note=E');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(output.frequencies.single, closeTo(329.63, 0.1)); // E4
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    // It opens the Drone tab, with the key lit.
    expect(find.bySemanticsLabel('Stop E'), findsOneWidget);

    await tester.binding.handlePushRoute('/open_section?section=drone');
    await tester.pump(const Duration(milliseconds: 300));
    final scope = AudioScope.of(tester.element(find.byType(HomeShell)));
    expect(scope.navigation.section, AppSection.drone);
  });
}
