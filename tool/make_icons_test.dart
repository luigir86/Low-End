// Draws the launcher icons from ScrollMarkPainter into the Android
// resources. Run with:  flutter test tool/make_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/widgets/scroll_mark.dart';

const _background = Color(0xFF2B1D16);

Future<void> _png(
  String path,
  int size,
  void Function(Canvas canvas, Size size) draw,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  draw(canvas, Size(size.toDouble(), size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('make the launcher icons', (tester) async {
    const res = 'android/app/src/main/res';
    // Density folders: launcher icon size, adaptive layer size (108 dp).
    const densities = {
      'mdpi': (48, 108),
      'hdpi': (72, 162),
      'xhdpi': (96, 216),
      'xxhdpi': (144, 324),
      'xxxhdpi': (192, 432),
    };
    await tester.runAsync(() async {
      for (final e in densities.entries) {
        final (icon, layer) = e.value;
        // Older phones: the whole icon, with rounded corners.
        await _png('$res/mipmap-${e.key}/ic_launcher.png', icon, (c, s) {
          c.clipRRect(
            RRect.fromRectAndRadius(
              Offset.zero & s,
              Radius.circular(s.width * 0.22),
            ),
          );
          c.drawRect(Offset.zero & s, Paint()..color = _background);
          // The art is drawn with margin for an adaptive mask: fill more.
          c.translate(s.width / 2, s.height / 2);
          c.scale(1.3);
          c.translate(-s.width / 2, -s.height / 2);
          const ScrollMarkPainter().paint(c, s);
        });
        await _png(
          '$res/mipmap-${e.key}/ic_launcher_foreground.png',
          layer,
          (c, s) => const ScrollMarkPainter().paint(c, s),
        );
        await _png(
          '$res/mipmap-${e.key}/ic_launcher_monochrome.png',
          layer,
          (c, s) => const ScrollMarkPainter(
            light: Colors.white,
            flat: true,
          ).paint(c, s),
        );
      }
    });
  });
}
