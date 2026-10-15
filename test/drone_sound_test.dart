import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/drone_sound.dart';
import 'package:low_end/audio/pitch_detector.dart';

void main() {
  const rate = DroneSound.sampleRate;

  test('the root is in tune to a tiny fraction of a cent', () {
    for (final hz in [261.63, 440.0, 493.88]) {
      final samples = DroneSound.loop([hz], [1]);
      final detector = PitchDetector(sampleRate: rate);
      final window = Float64List.sublistView(
        samples,
        1000,
        1000 + detector.windowSize,
      );
      final found = detector.detect(window)!;
      final cents = 1200 * math.log(found / hz) / math.ln2;
      expect(cents.abs(), lessThan(0.5), reason: '$hz Hz found as $found');
    }
  });

  test('loops without a click', () {
    final s = DroneSound.loop([440, 550, 660], [1, 0.7, 0.7]);
    // The jump from the last sample back to the first is no bigger than
    // the usual step between neighbouring samples.
    var largest = 0.0;
    for (var i = 1; i < s.length; i++) {
      largest = math.max(largest, (s[i] - s[i - 1]).abs());
    }
    expect((s.first - s.last).abs(), lessThanOrEqualTo(largest));
  });

  test('is rich in harmonics but never clips', () {
    final s = DroneSound.loop([261.63], [1]);
    final peak = s.map((v) => v.abs()).reduce(math.max);
    expect(peak, closeTo(0.85, 1e-9));
    // A pure sine crosses zero twice per cycle; overtones add more.
    var crossings = 0;
    for (var i = 1; i < rate; i++) {
      if ((s[i - 1] < 0) != (s[i] < 0)) crossings++;
    }
    expect(crossings, greaterThan(2 * 261.63 * 1.05));
  });
}
