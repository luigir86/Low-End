// Regression tests for the problems found in the first round of reviews.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/app_navigation.dart';
import 'package:low_end/app/home_shell.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/app/settings.dart';
import 'package:low_end/app/settings_page.dart';
import 'package:low_end/audio/audio_scope.dart';
import 'package:low_end/audio/mic_input.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/features/tuner/drone/drone_controller.dart';
import 'package:low_end/features/tuner/tuner_controller.dart';

/// Counts the calls to [play], to tell when the drone was retuned.
class _CountingOutput extends SilentToneOutput {
  var plays = 0;

  @override
  Future<void> play(List<double> f, List<double> gains, double v) {
    plays++;
    return super.play(f, gains, v);
  }
}

/// An output whose plays finish only when the test says so, and which
/// remembers how many ran at the same time.
class _GatedOutput implements ToneOutput {
  final gates = <Completer<void>>[];
  List<double> sounding = const [];
  var running = 0;
  var mostAtOnce = 0;

  @override
  Future<void> prepare(List<(List<double>, List<double>)> sounds) async {}

  @override
  Future<void> play(List<double> f, List<double> gains, double v) async {
    running++;
    mostAtOnce = math.max(mostAtOnce, running);
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    sounding = f;
    running--;
  }

  @override
  Future<void> stop() async => sounding = const [];

  void openAll() {
    for (final g in gates) {
      if (!g.isCompleted) g.complete();
    }
  }
}

Future<void> _flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<AudioScope> _pumpApp(
  WidgetTester tester, {
  MicInput? mic,
  ToneOutput? output,
  AppSettings? settings,
  String lang = 'en',
  Size size = const Size(1080, 2400),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 2.5;
  tester.platformDispatcher.localesTestValue = [Locale(lang)];
  tester.platformDispatcher.localeTestValue = Locale(lang);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    LowEndApp(
      toneOutput: output ?? SilentToneOutput(),
      micInput: mic ?? FakeMicInput(),
      settings: settings,
    ),
  );
  await _settle(tester);
  final scope = AudioScope.of(tester.element(find.byType(HomeShell)));
  // The app opens on the metronome; these checks are about the tuner.
  scope.navigation.open(AppSection.tuner);
  await _settle(tester);
  return scope;
}

/// The strobe and the now-playing dot move for ever, so pumpAndSettle would
/// never return.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('drone sound changes run one at a time', () {
    test(
      'a change during a start waits, then applies the latest state',
      () async {
        final out = _GatedOutput();
        final drone = DroneController(out);
        final starting = drone.tapNote(9);
        drone.setVoicing(DroneVoicing.chord);
        drone.setChord(ChordType.minor);
        await _flush();
        expect(out.gates, hasLength(1), reason: 'changes waited their turn');
        out.openAll();
        await starting;
        await _flush();
        out.openAll();
        await _flush();
        expect(out.mostAtOnce, 1);
        expect(out.sounding, [440, 528, 660]);
      },
    );
  });

  group('the app', () {
    testWidgets('a language or note-name change does not retune the drone', (
      tester,
    ) async {
      final output = _CountingOutput();
      final settings = AppSettings();
      final scope = await _pumpApp(tester, output: output, settings: settings);
      await scope.drone.tapNote(9);
      await tester.pump();
      final plays = output.plays;
      settings.setLanguage('it');
      await _settle(tester);
      settings.setNaming(NoteNaming.letters);
      await _settle(tester);
      expect(output.plays, plays);
      settings.setReferencePitch(442);
      await _settle(tester);
      expect(output.plays, plays + 1);
      await scope.drone.stop();
    });

    testWidgets('the microphone is off while the settings page covers the '
        'tuner, and on again when it closes', (tester) async {
      final mic = FakeMicInput();
      await _pumpApp(tester, mic: mic);
      expect(mic.isCapturing, isTrue);
      await tester.tap(find.byTooltip('Settings'));
      await _settle(tester);
      expect(mic.isCapturing, isFalse);
      await tester.tap(find.byType(BackButton));
      await _settle(tester);
      expect(mic.isCapturing, isTrue);
    });

    testWidgets('a pause by the player lasts across tabs, pages and the '
        'background', (tester) async {
      final mic = FakeMicInput();
      final scope = await _pumpApp(tester, mic: mic);
      await tester.tap(find.byKey(const Key('tunerHub')));
      await _settle(tester);
      expect(mic.isCapturing, isFalse);
      expect(find.text('Tuner paused: tap Listen'), findsOneWidget);

      scope.navigation.open(AppSection.drone);
      await _settle(tester);
      scope.navigation.open(AppSection.tuner);
      await _settle(tester);
      expect(mic.isCapturing, isFalse, reason: 'back on the tab');

      await tester.tap(find.byTooltip('Settings'));
      await _settle(tester);
      await tester.tap(find.byType(BackButton));
      await _settle(tester);
      expect(mic.isCapturing, isFalse, reason: 'back from the settings');

      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      await _settle(tester);
      expect(mic.isCapturing, isFalse, reason: 'back from the background');

      await tester.tap(find.byKey(const Key('tunerHub')));
      await _settle(tester);
      expect(mic.isCapturing, isTrue);
    });

    testWidgets('without a pause, the tuner listens again after the '
        'background and on its tab', (tester) async {
      final mic = FakeMicInput();
      final scope = await _pumpApp(tester, mic: mic);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      expect(mic.isCapturing, isFalse);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      await _settle(tester);
      expect(mic.isCapturing, isTrue);
      scope.navigation.open(AppSection.metronome);
      await _settle(tester);
      expect(mic.isCapturing, isFalse);
      scope.navigation.open(AppSection.tuner);
      await _settle(tester);
      expect(mic.isCapturing, isTrue);
      expect(scope.tuner.status, TunerStatus.listening);
    });

    testWidgets('cents below the note use a real minus sign', (tester) async {
      final mic = FakeMicInput();
      await _pumpApp(tester, mic: mic);
      // E1, 20 cents flat.
      final hz = 41.2 * math.pow(2, -20 / 1200);
      for (var chunk = 0; chunk < 10; chunk++) {
        mic.add(
          Float64List.fromList([
            for (var i = chunk * 1600; i < (chunk + 1) * 1600; i++)
              0.3 * math.sin(2 * math.pi * hz * i / 16000),
          ]),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.textContaining(RegExp('Flat −\\d+ cents')), findsOne);
      expect(find.textContaining('-'), findsNothing);
    });

    testWidgets('the chord menu shows only for a chord, and the dial names '
        'the chord', (tester) async {
      // A small phone with large text, in Italian: the longest labels.
      final scope = await _pumpApp(
        tester,
        lang: 'it',
        size: const Size(900, 1600),
        textScale: 1.5,
      );
      scope.navigation.open(AppSection.drone);
      await _settle(tester);
      // Its place is kept, so the rows line up, but it cannot be seen or
      // touched.
      expect(find.byType(DropdownMenu<ChordType>).hitTestable(), findsNothing);
      await tester.tap(find.text('La'));
      await _settle(tester);
      expect(find.text('La4'), findsOneWidget);
      expect(find.text('Tonica'), findsOneWidget, reason: 'switch only');

      await tester.tap(find.text('Accordo').first);
      await _settle(tester);
      expect(find.byType(DropdownMenu<ChordType>), findsOneWidget);
      expect(find.text('La maggiore'), findsOneWidget);
      scope.drone.setChord(ChordType.minor);
      await _settle(tester);
      expect(find.text('La minore'), findsOneWidget);
      scope.drone.setChord(ChordType.seventh);
      await _settle(tester);
      expect(find.text('La7'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await scope.drone.stop();
    });

    testWidgets('the reference A has its own heading in the settings', (
      tester,
    ) async {
      await _pumpApp(tester);
      await tester.tap(find.byTooltip('Settings'));
      await _settle(tester);
      // On the settings page (the tuner below it shows the same row).
      expect(
        find.descendant(
          of: find.byType(SettingsPage),
          matching: find.text('Reference A'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('The frequency of A4, for the tuner and the harmony.'),
        findsOneWidget,
      );
    });
  });

  test('Android keeps the settings out of cloud backups', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
  });
}
