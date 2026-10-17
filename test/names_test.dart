import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/app/settings.dart';
import 'package:low_end/audio/mic_input.dart';
import 'package:low_end/audio/piano_output.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/features/tuner/drone/harmony.dart';

Future<void> _open(
  WidgetTester tester, {
  String language = 'en',
  Size size = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    LowEndApp(
      toneOutput: SilentToneOutput(),
      pianoOutput: SilentPianoOutput(),
      micInput: FakeMicInput(),
      settings: AppSettings()..setLanguage(language),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(language == 'en' ? 'Harmony' : 'Armonia'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.text(language == 'en' ? 'Progression' : 'Progressione'),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the progression field says the song, the menu says more', (
    tester,
  ) async {
    await _open(tester);
    // Chosen, the field says only the name: the song would not fit.
    expect(find.text('II–V–I'), findsOneWidget);
    await tester.tap(find.byType(DropdownMenu<Progression>));
    await tester.pumpAndSettle();
    expect(find.text('Jazz standard, like Autumn Leaves'), findsOneWidget);
    expect(find.text('Jazz in a minor key, like Blue Bossa'), findsOneWidget);
    expect(find.text('Rock ’n’ roll, like Twist and Shout'), findsOneWidget);
    expect(find.text('’50s–’60s pop, like Stand by Me'), findsOneWidget);
    expect(find.text('Blues, like Sweet Home Chicago'), findsOneWidget);
    expect(find.text('12-bar blues'), findsOneWidget);
    await tester.tap(find.text('12-bar blues'));
    await tester.pumpAndSettle();
    expect(find.text('12-bar blues'), findsOneWidget);
    expect(find.textContaining('Sweet Home Chicago'), findsNothing);
  });

  testWidgets('in Italian, on a narrow phone, nothing overflows', (
    tester,
  ) async {
    await _open(tester, language: 'it', size: const Size(840, 1700));
    await tester.tap(find.byType(DropdownMenu<Progression>));
    await tester.pumpAndSettle();
    expect(find.text('Standard jazz, come Autumn Leaves'), findsOneWidget);
    expect(find.text('Blues in 12 battute'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('II–V–I minore'));
    await tester.pumpAndSettle();
    expect(find.text('II–V–I minore'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (language, text) in [
    (
      'en',
      'Thanks to the Power Flower Orchestra of Fossano, who inspired this app and put it to the test.',
    ),
    (
      'it',
      'Grazie alla Power Flower Orchestra di Fossano, che ha ispirato e provato quest’app.',
    ),
  ]) {
    testWidgets('the settings thank the Power Flower Orchestra ($language)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        LowEndApp(
          toneOutput: SilentToneOutput(),
          micInput: FakeMicInput(),
          settings: AppSettings()..setLanguage(language),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byTooltip(language == 'en' ? 'Settings' : 'Impostazioni'),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(text), 200);
      expect(find.text(text), findsOneWidget);
    });
  }
}
