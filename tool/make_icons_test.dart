// Makes the launcher icons and the logo of the About page from
// design/lion-logo.jpg, the lion's head on the dark blue background.
//   flutter test tool/make_icons_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The background of the logo, also the background layer of the adaptive
/// icon (see android/app/src/main/res/values/ic_launcher_background.xml).
const _background = Color(0xFF1B1411); // Palette.ebony

/// A slightly lighter glow behind the lion (Palette.walnutDeep).
const _glow = Color(0xFF2B1D16);

/// The cold slate of the original picture, which is swapped for the warm
/// background above.
const _oldBackground = (34.0, 38.0, 42.0);

/// The warm background with a soft glow in the middle, [s] pixels wide.
/// With [withBackground] false only the glow is drawn (adaptive foreground).
void _backdrop(Canvas canvas, double s, {bool withBackground = true}) {
  if (withBackground) {
    canvas.drawRect(Offset.zero & Size(s, s), Paint()..color = _background);
  }
  canvas.drawRect(
    Offset.zero & Size(s, s),
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(s / 2, s / 2),
        s * 0.55,
        const [_glow, Color(0x002B1D16)],
        const [0, 1],
      ),
  );
}

/// Takes the cold background out of the picture (it becomes transparent,
/// the lion's colours are unmixed from it), so any background fits behind.
Future<ui.Image> _unmix(ui.Image image) async {
  final w = image.width, h = image.height;
  final data = (await image.toByteData())!;
  final out = Uint8List(w * h * 4);
  for (var i = 0; i < w * h; i++) {
    final px = [
      data.getUint8(i * 4).toDouble(),
      data.getUint8(i * 4 + 1).toDouble(),
      data.getUint8(i * 4 + 2).toDouble(),
    ];
    final luma = 0.299 * px[0] + 0.587 * px[1] + 0.114 * px[2];
    final t = ((luma - 44) / 28).clamp(0.0, 1.0);
    final a = t * t * (3 - 2 * t);
    final bg = [_oldBackground.$1, _oldBackground.$2, _oldBackground.$3];
    for (var k = 0; k < 3; k++) {
      final v = a < 0.02 ? 0.0 : (px[k] - (1 - a) * bg[k]) / a;
      out[i * 4 + k] = v.clamp(0.0, 255.0).round();
    }
    out[i * 4 + 3] = (a * 255).round();
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(out);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: w,
    height: h,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  return (await codec.getNextFrame()).image;
}

/// Where the lion sits in the 1024-pixel picture: its box is x 294 to 730
/// and y 101 to 879, so its centre is at (512, 490).
const _centre = Offset(512, 490);
const _lionHeight = 778.0;

Future<ui.Image> _load() async {
  final bytes = File('design/lion-logo.jpg').readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  return _unmix((await codec.getNextFrame()).image);
}

/// Draws the lion at [size] pixels with its head and neck [fill] of the
/// height, centred, its edges fading into whatever is behind.
void _lion(Canvas canvas, ui.Image image, double size, double fill) {
  final scale = size * fill / _lionHeight;
  final side = image.width * scale;
  final rect = Rect.fromLTWH(
    size / 2 - _centre.dx * scale,
    size / 2 - _centre.dy * scale,
    side,
    side,
  );
  canvas.saveLayer(Offset.zero & Size(size, size), Paint());
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width * 1.0, image.height * 1.0),
    rect,
    Paint()..filterQuality = FilterQuality.high,
  );
  // The picture's own background fades out towards its edges, so that it
  // joins the plain background behind it without a seam.
  final c = rect.center;
  canvas.drawRect(
    rect,
    Paint()
      ..blendMode = BlendMode.dstIn
      ..shader = ui.Gradient.radial(
        c,
        side / 2,
        const [Colors.white, Colors.white, Color(0x00FFFFFF)],
        const [0, 0.78, 1],
      ),
  );
  canvas.restore();
}

Future<ui.Image> _render(
  int size,
  void Function(Canvas canvas, double size) draw,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  draw(canvas, size.toDouble());
  return recorder.endRecording().toImage(size, size);
}

Future<void> _save(String path, ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// The lion as a white shape on nothing, for the themed (monochrome) icon:
/// what is brighter than the background is kept.
Future<ui.Image> _mono(ui.Image lion) async {
  final size = lion.width;
  final data = (await lion.toByteData())!;
  final out = Uint8List(size * size * 4);
  for (var i = 0; i < size * size; i++) {
    final r = data.getUint8(i * 4);
    final g = data.getUint8(i * 4 + 1);
    final b = data.getUint8(i * 4 + 2);
    final luma = 0.299 * r + 0.587 * g + 0.114 * b;
    // The background is about 37; the lion's lightest dark line, a bit
    // more; its wood, 90 and over.
    final alpha = ((luma - 52) / 36).clamp(0.0, 1.0);
    out[i * 4] = 255;
    out[i * 4 + 1] = 255;
    out[i * 4 + 2] = 255;
    out[i * 4 + 3] = (alpha * 255).round();
  }
  final completer = ui.ImmutableBuffer.fromUint8List(out).then((buffer) async {
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: size,
      height: size,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    return (await codec.getNextFrame()).image;
  });
  return completer;
}

void main() {
  testWidgets('make the launcher icons and the logo', (tester) async {
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
      final picture = await _load();
      for (final e in densities.entries) {
        final (icon, layer) = e.value;
        // Older phones: the whole icon, with rounded corners.
        await _save(
          '$res/mipmap-${e.key}/ic_launcher.png',
          await _render(icon, (c, s) {
            c.clipRRect(
              RRect.fromRectAndRadius(
                Offset.zero & Size(s, s),
                Radius.circular(s * 0.22),
              ),
            );
            _backdrop(c, s);
            _lion(c, picture, s, 0.80);
          }),
        );
        // Adaptive icons: only the middle 66 of the 108 dp always shows.
        await _save(
          '$res/mipmap-${e.key}/ic_launcher_foreground.png',
          await _render(layer, (c, s) {
            _backdrop(c, s, withBackground: false);
            _lion(c, picture, s, 0.60);
          }),
        );
        final lion = await _render(layer, (c, s) {
          _backdrop(c, s);
          _lion(c, picture, s, 0.60);
        });
        await _save(
          '$res/mipmap-${e.key}/ic_launcher_monochrome.png',
          await _mono(lion),
        );
      }
      // The logo of the About page.
      await _save(
        'assets/brand/logo.png',
        await _render(192, (c, s) {
          c.clipRRect(
            RRect.fromRectAndRadius(
              Offset.zero & Size(s, s),
              Radius.circular(s * 0.22),
            ),
          );
          _backdrop(c, s);
          _lion(c, picture, s, 0.82);
        }),
      );
      // Not used by the app: a large version for the store listing.
      await _save(
        'design/icon-512.png',
        await _render(512, (c, s) {
          _backdrop(c, s);
          _lion(c, picture, s, 0.80);
        }),
      );
      File('design/icon-512.png').copySync('store/graphics/icon-512.png');
      expect(math.min(picture.width, picture.height), 1024);
    });
  });
}
