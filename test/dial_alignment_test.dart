import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/audio/click_output.dart';
import 'package:low_end/audio/mic_input.dart';
import 'package:low_end/audio/tone_output.dart';
import 'package:low_end/widgets/dial.dart';

/// The three round dials (beats, circle of fifths, strobe) and the rows under
/// them must sit in the same place on every tab: moving between tabs, only
/// what is drawn inside them changes.
void main() {
  Future<void> open(
    WidgetTester tester,
    Size size,
    double scale, {
    MicInput? mic,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(
      LowEndApp(
        toneOutput: SilentToneOutput(),
        clickOutput: SilentClickOutput(),
        micInput: mic ?? FakeMicInput(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// The dial box and the three rows of the section on screen.
  List<Rect> geometry(WidgetTester tester) {
    final layouts = find.byType(DialLayout);
    final onScreen = [
      for (var i = 0; i < layouts.evaluate().length; i++)
        if (tester.getRect(layouts.at(i)).left == 0) i,
    ];
    expect(onScreen, hasLength(1), reason: 'one section on screen');
    final layout = layouts.at(onScreen.single);
    final boxes = find.descendant(
      of: layout,
      matching: find.byType(ConstrainedBox),
    );
    final rows = <Rect>[];
    for (final e in boxes.evaluate()) {
      final box = e.renderObject! as RenderBox;
      final c = (e.widget as ConstrainedBox).constraints;
      if (c.minHeight == DialLayout.rowHeight) {
        rows.add(box.localToGlobal(Offset.zero) & box.size);
      }
    }
    expect(rows, hasLength(3), reason: 'dial, then three rows');
    final dial = find.descendant(
      of: layout,
      matching: find.byWidgetPredicate(
        (w) => w is SizedBox && w.width != null && w.width == w.height,
      ),
    );
    final d = tester.getRect(dial.first);
    return [d, ...rows];
  }

  Future<List<List<Rect>>> allTabs(WidgetTester tester) async {
    final all = <List<Rect>>[];
    for (final tab in ['Metronome', 'Harmony', 'Tuner']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(milliseconds: 400));
      all.add(geometry(tester));
    }
    return all;
  }

  for (final (size, scale) in [
    (const Size(390, 844), 1.0),
    (const Size(360, 640), 1.0),
    (const Size(360, 640), 1.5),
  ]) {
    testWidgets('dials and rows are aligned on $size at x$scale', (
      tester,
    ) async {
      await open(tester, size, scale);
      final tabs = await allTabs(tester);
      for (final g in tabs) {
        expect(g.length, 4);
        expect(g[0].center.dy, tabs[0][0].center.dy);
        expect(g[0].size, tabs[0][0].size);
        for (var i = 1; i < 4; i++) {
          expect(g[i].top, tabs[0][i].top, reason: 'row $i');
        }
      }
    });
  }

  testWidgets('the three rows are equal, slider row included', (tester) async {
    await open(tester, const Size(390, 844), 1.0);
    for (final g in await allTabs(tester)) {
      // The same height and no space between them, whatever is in them:
      // the rows of controls and the slider's are one measure.
      for (var i = 1; i < 4; i++) {
        expect(g[i].height, DialLayout.rowHeight);
      }
      expect(g[2].top, g[1].bottom);
      expect(g[3].top, g[2].bottom);
    }
  });

  testWidgets('the dial stays put when the tuner shows a long message', (
    tester,
  ) async {
    await open(
      tester,
      const Size(390, 844),
      1.0,
      mic: FakeMicInput(allowed: false),
    );
    final tabs = await allTabs(tester);
    expect(tabs[2][0].center.dy, tabs[0][0].center.dy);
    expect(tabs[2][0].size, tabs[0][0].size);
  });
}
