import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/app_navigation.dart';
import 'package:low_end/app/background_audio.dart';
import 'package:low_end/app/settings.dart';
import 'package:low_end/features/metronome/metronome_controller.dart';
import 'package:low_end/app/home_shell.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/app/screen_awake.dart';
import 'package:low_end/audio/audio_scope.dart';
import 'package:low_end/audio/click_output.dart';
import 'package:low_end/audio/mic_input.dart';
import 'package:low_end/audio/piano_output.dart';
import 'package:low_end/features/tuner/drone/drone_controller.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:low_end/widgets/pulsing_dot.dart';

/// The Harmony and Metronome tabs: their names are also under the balance
/// slider.
final _harmonyTab = find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text('Harmony'),
);
final _metronomeTab = find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text('Metronome'),
);

void main() {
  testWidgets('shows the three main sections and switches between them', (
    tester,
  ) async {
    await tester.pumpWidget(
      LowEndApp(toneOutput: SilentToneOutput(), micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tuner'), findsOneWidget);
    expect(_harmonyTab, findsOneWidget);
    expect(_metronomeTab, findsOneWidget);
    expect(find.text('Library'), findsNothing);

    await tester.tap(_metronomeTab);
    await tester.pumpAndSettle();
    expect(find.text('Tap to start'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
    expect(find.text('TAP'), findsOneWidget);
  });

  testWidgets('the ring follows the time signature at once, also stopped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      LowEndApp(toneOutput: SilentToneOutput(), micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();

    // The ring is the metronome's own painter (the one with a time
    // signature).
    dynamic painter() => tester
        .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
        .map((r) => r.painter)
        .where((p) => p != null && p.toString().contains('_RingPainter'))
        .single;

    final before = painter();
    expect(before.signature.label, '4/4');
    await tester.tap(find.text('4/4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6/8').last);
    await tester.pumpAndSettle();
    // Not playing, and yet the ring is drawn again, in six.
    final after = painter();
    expect(after.signature.label, '6/8');
    expect(after.shouldRepaint(before), isTrue);
  });

  testWidgets('swiping moves between the sections', (tester) async {
    await tester.pumpWidget(
      LowEndApp(toneOutput: SilentToneOutput(), micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();
    final scope = AudioScope.of(tester.element(find.byType(HomeShell)));
    expect(scope.navigation.section, AppSection.metronome);

    // Swipe on the empty top of the page, away from the dial.
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(scope.navigation.section, AppSection.drone);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(scope.navigation.section, AppSection.tuner);
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(scope.navigation.section, AppSection.drone);
  });

  testWidgets('holding a tab starts and stops its sound', (tester) async {
    final tone = SilentToneOutput();
    final click = SilentClickOutput();
    await tester.pumpWidget(
      LowEndApp(toneOutput: tone, clickOutput: click, micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();

    await tester.longPress(_metronomeTab);
    await tester.pump(const Duration(milliseconds: 300));
    expect(click.bar, isNotNull);
    await tester.longPress(_metronomeTab);
    await tester.pump(const Duration(milliseconds: 300));
    expect(click.bar, isNull);

    await tester.longPress(_harmonyTab);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies, isNotEmpty);
    // Still on the Metronome tab: holding does not switch.
    expect(find.text('Tap to start'), findsOneWidget);
  });

  testWidgets('drone and metronome play together, pause on the tuner with a '
      'notice, and start again only when asked', (tester) async {
    final tone = SilentToneOutput();
    final click = SilentClickOutput();
    final mic = FakeMicInput();
    final awake = FakeScreenAwake();
    await tester.pumpWidget(
      LowEndApp(
        toneOutput: tone,
        clickOutput: click,
        micInput: mic,
        screenAwake: awake,
      ),
    );
    await tester.pumpAndSettle();
    expect(awake.on, isFalse);

    await tester.tap(_harmonyTab);
    await tester.pumpAndSettle();
    expect(find.byType(PulsingDot), findsNothing);
    await tester.tap(find.text('A'));
    // pumpAndSettle would wait forever on the pulsing dots.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies.single, closeTo(440, 0.01));

    await tester.tap(_metronomeTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Tap to start'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(click.bar, isNotNull);
    // A dot on each playing tab, and no strip to stop them from elsewhere.
    expect(find.byType(PulsingDot), findsNWidgets(2));
    expect(find.byTooltip('Stop Harmony · A4'), findsNothing);
    // The screen stays on while they play.
    expect(awake.on, isTrue);

    // The tuner pauses both, so the microphone hears only the bass, and
    // says so.
    await tester.tap(find.text('Tuner'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies, isEmpty);
    expect(click.bar, isNull);
    expect(mic.isCapturing, isTrue);
    expect(find.byType(PulsingDot), findsNothing);
    expect(find.text('Paused while you tune'), findsOneWidget);
    // Listening keeps the screen on too.
    expect(awake.on, isTrue);

    // Leaving it, nothing starts by itself: a swipe too far must not bring
    // the click back unasked.
    await tester.tap(_harmonyTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies, isEmpty);
    expect(click.bar, isNull);
    expect(mic.isCapturing, isFalse);
    expect(awake.on, isFalse);

    // Resume, on the notice, plays both again.
    await tester.tap(find.text('Resume'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies.single, closeTo(440, 0.01));
    expect(click.bar, isNotNull);
    expect(find.byType(PulsingDot), findsNWidgets(2));
  });

  testWidgets('a page opened over the tuner does not pause the sound again', (
    tester,
  ) async {
    final click = SilentClickOutput();
    await tester.pumpWidget(
      LowEndApp(
        toneOutput: SilentToneOutput(),
        clickOutput: click,
        micInput: FakeMicInput(),
      ),
    );
    await tester.pumpAndSettle();
    final scope = AudioScope.of(tester.element(find.byType(HomeShell)));
    scope.navigation.open(AppSection.tuner);
    await tester.pump(const Duration(milliseconds: 300));
    // Played again from the tuner, on purpose (with headphones, say).
    await scope.metronome.start();
    scope.navigation.setCovered(true);
    await tester.pump(const Duration(milliseconds: 300));
    scope.navigation.setCovered(false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(scope.metronome.isPlaying, isTrue);
    expect(click.bar, isNotNull);
    await scope.metronome.stop();
  });

  testWidgets('with the microphone refused, a button opens the settings', (
    tester,
  ) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('low_end/app_settings'),
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('low_end/app_settings'),
        null,
      ),
    );
    await tester.pumpWidget(
      LowEndApp(
        toneOutput: SilentToneOutput(),
        micInput: FakeMicInput(allowed: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tuner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open settings'));
    await tester.pump();
    expect(calls, ['open']);
  });

  testWidgets('holding a tab on the tuner does not start the sound', (
    tester,
  ) async {
    final click = SilentClickOutput();
    final mic = FakeMicInput();
    await tester.pumpWidget(
      LowEndApp(
        toneOutput: SilentToneOutput(),
        clickOutput: click,
        micInput: mic,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tuner'));
    await tester.pumpAndSettle();
    expect(mic.isCapturing, isTrue);
    await tester.longPress(_metronomeTab);
    await tester.pump(const Duration(milliseconds: 300));
    expect(click.bar, isNull);
    // Still a hint for screen readers, and the tab says when it plays.
    final scope = AudioScope.of(tester.element(find.byType(HomeShell)));
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(_metronomeTab),
      isSemantics(onLongPressHint: 'Hold to start or stop'),
    );
    expect(tester.getSemantics(_metronomeTab).value, isEmpty);
    // Paused, the tuner lets a hold start it.
    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(scope.tuner.isListening, isFalse);
    await tester.longPress(_metronomeTab);
    await tester.pump(const Duration(milliseconds: 300));
    expect(click.bar, isNotNull);
    expect(tester.getSemantics(_metronomeTab).value, 'Playing');
    handle.dispose();
    await scope.metronome.stop();
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
      await tester.tap(_metronomeTab);
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
    await tester.tap(_harmonyTab);
    await tester.pumpAndSettle();
    await tester.tap(find.text('D'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tone.frequencies, isNotEmpty);

    await tester.tap(find.bySemanticsLabel(RegExp('^Stop the harmony')));
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
    // The reference A is further down the page now.
    await tester.scrollUntilVisible(find.text('440 Hz'), 100);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('440 Hz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('442 Hz').last);
    await tester.pumpAndSettle();

    // The app is in Italian now, so the back button says "Indietro".
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Armonia'),
      ),
    );
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

  testWidgets('the notification says what plays and follows the tempo', (
    tester,
  ) async {
    final audio = _RecordingAudio();
    await tester.pumpWidget(
      LowEndApp(
        toneOutput: SilentToneOutput(),
        clickOutput: SilentClickOutput(),
        micInput: FakeMicInput(),
        backgroundAudio: audio,
      ),
    );
    await tester.pumpAndSettle();
    final scope = AudioScope.of(tester.element(find.byType(HomeShell)));

    await scope.metronome.start();
    await tester.pump();
    expect(audio.state, MediaState.playing);
    expect(audio.text, 'Metronome 80 BPM · 4/4');
    scope.metronome.setBpm(100);
    await tester.pump();
    expect(audio.text, 'Metronome 100 BPM · 4/4');
    await scope.drone.start();
    await tester.pump();
    expect(audio.text, 'Metronome 100 BPM · 4/4 · Harmony A');

    await scope.metronome.stop();
    await tester.pump();
    expect(audio.text, 'Harmony A');
    await scope.drone.stop();
    await tester.pump();
    expect(audio.state, MediaState.off);
  });

  testWidgets('the theme can be forced, and the screen kept on or not', (
    tester,
  ) async {
    final settings = AppSettings();
    final awake = FakeScreenAwake();
    final click = SilentClickOutput();
    await tester.pumpWidget(
      LowEndApp(
        toneOutput: SilentToneOutput(),
        clickOutput: click,
        micInput: FakeMicInput(),
        settings: settings,
        screenAwake: awake,
      ),
    );
    await tester.pumpAndSettle();
    final scope = AudioScope.of(tester.element(find.byType(HomeShell)));
    brightness() => Theme.of(tester.element(find.byType(HomeShell))).brightness;

    // The test window is light, and the app follows it until told otherwise.
    expect(brightness(), Brightness.light);
    settings.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    settings.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);

    // The screen stays on while it plays, unless the player says no.
    await scope.metronome.start();
    await tester.pump();
    expect(awake.on, isTrue);
    settings.setKeepScreenOn(false);
    await tester.pump();
    expect(awake.on, isFalse);
    settings.setKeepScreenOn(true);
    await tester.pump();
    expect(awake.on, isTrue);
    await scope.metronome.stop();
    await tester.pump();
    expect(awake.on, isFalse);
  });

  testWidgets('the settings page changes the theme and the screen option', (
    tester,
  ) async {
    final settings = AppSettings();
    await tester.pumpWidget(
      LowEndApp(
        toneOutput: SilentToneOutput(),
        micInput: FakeMicInput(),
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(settings.themeMode, ThemeMode.dark);
    await tester.tap(find.text('Keep the screen on'));
    await tester.pumpAndSettle();
    expect(settings.keepScreenOn, isFalse);
  });

  testWidgets('the guide opens by itself once, and from the settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    expect(settings.seenGuide, isFalse);
    await tester.pumpWidget(
      LowEndApp(
        toneOutput: SilentToneOutput(),
        micInput: FakeMicInput(),
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gestures and shortcuts'), findsOneWidget);
    expect(settings.seenGuide, isTrue);
    await tester.ensureVisible(find.text('Got it'));
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Gestures and shortcuts'), findsNothing);

    // Remembered: the next launch does not show it again.
    expect((await AppSettings.load()).seenGuide, isTrue);

    // And it can be read again from the settings.
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Gestures and shortcuts'), 100);
    await tester.tap(find.text('Gestures and shortcuts'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('the balance is named on both sides, the style is easy to hit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      LowEndApp(toneOutput: SilentToneOutput(), micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();
    // Under the slider the same names as the tabs, and what it is for.
    expect(find.text('Balance'), findsOneWidget);
    expect(find.text('Metronome'), findsNWidgets(2));
    expect(find.text('Harmony'), findsNWidgets(2));
    // The time signature button says what it is.
    expect(find.text('Time signature'), findsOneWidget);
    // The tuner tab is a microphone.
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
  });

  testWidgets('the sound options set the octave and where the chord sits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final piano = SilentPianoOutput();
    await tester.pumpWidget(
      LowEndApp(
        toneOutput: SilentToneOutput(),
        pianoOutput: piano,
        micInput: FakeMicInput(),
      ),
    );
    await tester.pumpAndSettle();
    final scope = AudioScope.of(tester.element(find.byType(HomeShell)));
    await tester.tap(_harmonyTab);
    await tester.pumpAndSettle();
    scope.drone.setVoicing(DroneVoicing.chord);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sound options'));
    await tester.pumpAndSettle();
    // The root of the key (A), in each octave.
    expect(find.text('A2'), findsOneWidget);
    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();
    expect(scope.drone.octave, 2);

    await tester.tap(find.text('No root'));
    await tester.pumpAndSettle();
    expect(scope.drone.shape, ChordShape.rootless);
    await tester.tap(find.text('Arpeggio'));
    await tester.pumpAndSettle();
    expect(scope.drone.style, DroneStyle.arpeggio);
  });

  testWidgets('touching the tempo opens the keyboard to type it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      LowEndApp(toneOutput: SilentToneOutput(), micInput: FakeMicInput()),
    );
    await tester.pumpAndSettle();
    final scope = AudioScope.of(tester.element(find.byType(HomeShell)));

    await tester.tap(find.text('80'));
    await tester.pumpAndSettle();
    expect(find.text('Type the tempo'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '132');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(scope.metronome.bpm, 132);
    expect(find.text('Type the tempo'), findsNothing);

    // Too fast is brought back to the limit, and a preset sets it at once.
    await tester.tap(find.text('132'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '999');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(scope.metronome.bpm, MetronomeController.maxBpm);
    await tester.tap(find.text('250'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('60'));
    await tester.pumpAndSettle();
    expect(scope.metronome.bpm, 60);

    // Cancelling leaves it as it was.
    await tester.tap(find.text('60').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '90');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(scope.metronome.bpm, 60);
  });
}

/// A [BackgroundAudio] that remembers what the notification shows.
class _RecordingAudio implements BackgroundAudio {
  var state = MediaState.off;
  var text = '';

  @override
  Stream<MediaCommand> get commands => const Stream.empty();

  @override
  Future<void> show(
    MediaState state, {
    required String title,
    String text = '',
  }) async {
    this.state = state;
    this.text = text;
  }
}
