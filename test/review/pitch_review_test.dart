import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/pitch_detector.dart';

const _rate = 16000;
final _detector = PitchDetector(sampleRate: _rate);

/// A plucked-string-like tone: [amps] for harmonics 1, 2, 3…, optional
/// noise and a slow decay.
Float64List _tone(
  double hz, {
  List<double> amps = const [1],
  double level = 0.3,
  double noise = 0,
  double decay = 0,
  int? length,
  int seed = 1,
  double offset = 0,
}) {
  final rnd = math.Random(seed);
  final n = length ?? _detector.windowSize;
  return Float64List.fromList([
    for (var i = 0; i < n; i++)
      offset +
          level *
              math.exp(-decay * i / _rate) *
              [
                for (var h = 0; h < amps.length; h++)
                  amps[h] *
                      math.sin(2 * math.pi * hz * (h + 1) * i / _rate + h),
              ].fold<double>(0, (a, b) => a + b) +
          noise * (rnd.nextDouble() * 2 - 1),
  ]);
}

double _cents(double a, double b) => 1200 * math.log(a / b) / math.ln2;

void main() {
  test('window covers three periods of 28 Hz', () {
    expect(_detector.windowSize, greaterThanOrEqualTo(3 * _rate / 28));
  });

  group('real-ish bass signals', () {
    test('low B (30.87 Hz) pure', () {
      final hz = _detector.detect(_tone(30.87))!;
      expect(_cents(hz, 30.87).abs(), lessThan(2));
    });

    test('low B with typical string harmonics', () {
      final hz = _detector.detect(_tone(30.87, amps: [1, 0.8, 0.6, 0.4, 0.3]))!;
      expect(_cents(hz, 30.87).abs(), lessThan(3));
    });

    test('low B with a weak fundamental (small speaker / phone mic)', () {
      // Phone microphones roll off below ~80 Hz, so the fundamental of the
      // low strings comes in much weaker than the 2nd and 3rd harmonics.
      final hz = _detector.detect(_tone(30.87, amps: [0.15, 1, 0.8, 0.5]));
      expect(hz, isNotNull);
      expect(_cents(hz!, 30.87).abs(), lessThan(5), reason: 'got $hz Hz');
    });

    test('E1 (41.2 Hz) with a weak fundamental', () {
      final hz = _detector.detect(_tone(41.2, amps: [0.2, 1, 0.7, 0.4]));
      expect(hz, isNotNull);
      expect(_cents(hz!, 41.2).abs(), lessThan(5), reason: 'got $hz Hz');
    });

    test('A1 (55 Hz) with harmonics and noise', () {
      final hz = _detector.detect(
        _tone(55, amps: [1, 0.7, 0.5, 0.3], noise: 0.05),
      )!;
      expect(_cents(hz, 55).abs(), lessThan(3));
    });

    test('G2 (98 Hz) with a DC offset and decay', () {
      final hz = _detector.detect(
        _tone(98, amps: [1, 0.5], offset: 0.2, decay: 3),
      )!;
      expect(_cents(hz, 98).abs(), lessThan(3));
    });

    test('notes across the range within 2 cents', () {
      for (var midi = 23; midi <= 76; midi++) {
        final f = 440 * math.pow(2, (midi - 69) / 12).toDouble();
        final hz = _detector.detect(_tone(f, amps: [1, 0.5, 0.3]));
        expect(hz, isNotNull, reason: 'midi $midi');
        expect(_cents(hz!, f).abs(), lessThan(2), reason: 'midi $midi: $hz');
      }
    });

    test('clipped (square-ish) E1 still reads E1', () {
      final raw = _tone(41.2, level: 3);
      final clipped = Float64List.fromList([
        for (final s in raw) s.clamp(-1.0, 1.0),
      ]);
      final hz = _detector.detect(clipped)!;
      expect(_cents(hz, 41.2).abs(), lessThan(3));
    });
  });

  group('no note', () {
    test('silence and very quiet hum', () {
      expect(_detector.detect(Float64List(_detector.windowSize)), isNull);
      expect(_detector.detect(_tone(55, level: 0.001)), isNull);
    });

    test('white noise', () {
      expect(_detector.detect(_tone(55, level: 0, noise: 0.3)), isNull);
    });

    test('constant DC', () {
      expect(_detector.detect(_tone(55, level: 0, offset: 0.5)), isNull);
    });

    test('short buffers do not throw', () {
      for (final n in [0, 1, 2, 3, 10, 44, 45, 100]) {
        expect(
          () => _detector.detect(_tone(400, length: n), expected: 400),
          returnsNormally,
          reason: 'length $n',
        );
      }
    });
  });

  group('sounds above 700 Hz', () {
    for (final f in [750.0, 880.0, 1000.0, 1500.0, 3000.0]) {
      test('$f Hz is ignored', () {
        expect(_detector.detect(_tone(f)), isNull);
      });
    }

    // A whistle or a voice right after a note: the high sound must not be
    // read as the old note through the "hold" path, since its period
    // divides the old one evenly.
    for (final (f, held) in [(880.0, 55.0), (1320.0, 110.0), (987.77, 61.74)]) {
      test('$f Hz right after $held Hz is not read as $held Hz', () {
        expect(_detector.detect(_tone(f), expected: held), isNull);
      });
    }
  });

  group('expected (hold) path', () {
    test('follows a fading note that no longer passes the strict test', () {
      // A1 buried in noise: no strict dip, but near the expected note.
      var rescued = 0;
      for (var noise = 0.05; noise < 0.6; noise += 0.025) {
        final samples = _tone(55, amps: [1, 0.5], noise: noise, seed: 7);
        final strict = _detector.detect(samples);
        final held = _detector.detect(samples, expected: 55);
        if (strict == null && held != null) {
          rescued++;
          expect(_cents(held, 55).abs(), lessThan(10));
        }
      }
      expect(rescued, greaterThan(0));
    });

    test('does not hold onto noise', () {
      expect(
        _detector.detect(_tone(55, level: 0, noise: 0.3), expected: 55),
        isNull,
      );
    });

    test('expected outside the range is harmless', () {
      for (final e in [1.0, 10.0, 27.0, 701.0, 5000.0, 20000.0]) {
        expect(
          () => _detector.detect(_tone(55, level: 0, noise: 0.3), expected: e),
          returnsNormally,
        );
      }
    });

    test('a new note a semitone away is not pulled to the old one', () {
      final hz = _detector.detect(_tone(58.27), expected: 55)!;
      expect(_cents(hz, 58.27).abs(), lessThan(3));
    });
  });
}
