// Swaps the cold slate background of the feature graphics for the warm
// ebony of the app (with a soft glow behind the lion), leaving the lion and
// the text as they are. The foreground is unmixed from the old background,
// so the edges stay clean.
//   flutter test tool/recolor_store_graphics_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _old = [34.0, 38.0, 42.0];
const _ebony = [0x1B, 0x14, 0x11];
const _glow = [0x2B, 0x1D, 0x16]; // Palette.walnutDeep

/// The lion's centre and the glow's radius, in pixels of the 1024x500 picture.
const _cx = 285.0, _cy = 240.0, _radius = 330.0;

void main() {
  testWidgets('recolor the feature graphics', (tester) async {
    await tester.runAsync(() async {
      for (final locale in ['en-US', 'it-IT']) {
        final path = 'store/graphics/$locale/feature-graphic-1024x500.png';
        final codec = await ui.instantiateImageCodec(
          File(path).readAsBytesSync(),
        );
        final image = (await codec.getNextFrame()).image;
        final w = image.width, h = image.height;
        final data = (await image.toByteData())!;
        final out = Uint8List(w * h * 4);
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            final i = (y * w + x) * 4;
            final r = data.getUint8(i).toDouble();
            final g = data.getUint8(i + 1).toDouble();
            final b = data.getUint8(i + 2).toDouble();
            final luma = 0.299 * r + 0.587 * g + 0.114 * b;
            final a = ((luma - 39) / 110).clamp(0.0, 1.0);
            final dx = x - _cx, dy = (y - _cy) * 1.1;
            final d = (dx * dx + dy * dy) / (_radius * _radius);
            final k = d >= 1 ? 0.0 : (1 - d) * (1 - d);
            final px = [r, g, b];
            for (var c = 0; c < 3; c++) {
              final bg = _ebony[c] + (_glow[c] - _ebony[c]) * k;
              out[i + c] = (px[c] + (1 - a) * (bg - _old[c]))
                  .clamp(0, 255)
                  .round();
            }
            out[i + 3] = 255;
          }
        }
        final buffer = await ui.ImmutableBuffer.fromUint8List(out);
        final descriptor = ui.ImageDescriptor.raw(
          buffer,
          width: w,
          height: h,
          pixelFormat: ui.PixelFormat.rgba8888,
        );
        final result =
            (await (await descriptor.instantiateCodec()).getNextFrame()).image;
        final png = await result.toByteData(format: ui.ImageByteFormat.png);
        File(path).writeAsBytesSync(png!.buffer.asUint8List());
      }
    });
  });
}
