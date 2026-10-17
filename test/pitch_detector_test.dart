import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/pitch_detector.dart';

const _rate = 16000;

/// A bowed or plucked string, roughly: a fundamental plus decaying overtones.
Float64List _string(double hz, int length, {List<double>? harmonics}) {
  final amps = harmonics ?? [1, 0.6, 0.4, 0.3, 0.2];
  return Float64List.fromList([
    for (var i = 0; i < length; i++)
      0.3 *
          [
            for (var h = 0; h < amps.length; h++)
              amps[h] * math.sin(2 * math.pi * hz * (h + 1) * i / _rate),
          ].reduce((a, b) => a + b),
  ]);
}

void main() {
  final detector = PitchDetector(sampleRate: _rate);
  final n = detector.windowSize;

  test('finds the open strings of basses within a cent', () {
    for (final hz in [30.87, 41.20, 55.0, 73.42, 98.0, 130.81, 220.0]) {
      final found = detector.detect(_string(hz, n));
      expect(found, isNotNull, reason: '$hz Hz');
      final cents = 1200 * math.log(found! / hz) / math.ln2;
      expect(cents.abs(), lessThan(1), reason: '$hz Hz found as $found');
    }
  });

  test('finds a low E whose fundamental is weaker than its overtones', () {
    final found = detector.detect(
      _string(41.2, n, harmonics: [0.3, 1, 0.7, 0.5]),
    );
    expect(found, closeTo(41.2, 0.5));
  });

  test('stays quiet on silence and noise', () {
    expect(detector.detect(Float64List(n)), isNull);
    final random = math.Random(1);
    final noise = Float64List.fromList([
      for (var i = 0; i < n; i++) random.nextDouble() * 0.6 - 0.3,
    ]);
    expect(detector.detect(noise), isNull);
  });

  test('keeps following a fading string through the noise', () {
    // A quiet A string, as it rings out, under room noise.
    final random = math.Random(2);
    final string = _string(55, n);
    final fading = Float64List.fromList([
      for (var i = 0; i < n; i++)
        string[i] * 0.12 + (random.nextDouble() - 0.5) * 0.06,
    ]);
    expect(detector.detect(fading), isNull);
    expect(detector.detect(fading, expected: 55), closeTo(55, 0.5));
    // But it does not invent a note that was not there.
    expect(detector.detect(fading, expected: 82.4), isNull);
  });

  test('hears a bass played without an amplifier, which is faint', () {
    Float64List faint(double hz, double gain) => Float64List.fromList([
      for (final s in _string(hz, n, harmonics: [0.4, 1, 0.8, 0.5])) s * gain,
    ]);
    // About 0.0015 of full scale: well under the old level of 0.003.
    final quiet = faint(41.2, 0.008);
    expect(quiet.map((s) => s * s).reduce((a, b) => a + b) / n, lessThan(1e-5));
    expect(detector.detect(quiet), closeTo(41.2, 0.5));
    // A string ringing out keeps being followed below the level at which
    // a new note is noticed.
    final dying = faint(55, 0.0025);
    expect(detector.detect(dying), isNull);
    expect(detector.detect(dying, expected: 55), closeTo(55, 0.5));
    // Silence is still silence, with or without a note before.
    expect(detector.detect(Float64List(n), expected: 55), isNull);
  });

  test('ignores sounds above the bass range', () {
    expect(detector.detect(_string(880, n, harmonics: [1])), isNull);
  });
}
