import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/click_sound.dart';
import 'package:low_end/audio/drone_sound.dart';

/// Writes WAV files to listen to the drone: four seconds each, the old pure
/// sines next to the new tone. Run with
/// `flutter test test_screenshots/audio` and open dist/preview/.
void main() {
  Float64List repeat(Float64List loop, int seconds) {
    final n = DroneSound.sampleRate * seconds;
    return Float64List.fromList([
      for (var i = 0; i < n; i++) loop[i % loop.length],
    ]);
  }

  Float64List sines(List<double> f, List<double> g) {
    const n = DroneSound.sampleRate * 4;
    return Float64List.fromList([
      for (var i = 0; i < n; i++)
        0.8 /
            f.length *
            [
              for (var v = 0; v < f.length; v++)
                g[v] * math.sin(2 * math.pi * f[v] * i / DroneSound.sampleRate),
            ].reduce((a, b) => a + b),
    ]);
  }

  test('write previews', () {
    final out = Directory('dist/preview')..createSync(recursive: true);
    const a = 440.0;
    final cases = {
      'la_fondamentale': ([a], [1.0]),
      'la_minore': ([a, a * 6 / 5, a * 3 / 2], [1.0, 0.7, 0.7]),
    };
    for (final MapEntry(key: name, value: (f, g)) in cases.entries) {
      File('${out.path}/drone_${name}_prima.wav')
          .writeAsBytesSync(ClickSound.wav(sines(f, g)));
      File('${out.path}/drone_${name}_nuovo.wav')
          .writeAsBytesSync(ClickSound.wav(repeat(DroneSound.loop(f, g), 4)));
    }
  });
}
