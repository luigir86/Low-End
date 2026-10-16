import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/soloud_engine.dart';

void main() {
  const warmUp = Duration(milliseconds: 80);

  test('the first sound waits for the engine to warm up', () async {
    var started = 0;
    final engine = EngineStarter(() async => started++, warmUp: warmUp);
    final clock = Stopwatch()..start();
    await engine.ensure();
    expect(started, 1);
    // Silence after the start, so that the first click is not smeared.
    expect(clock.elapsed, greaterThanOrEqualTo(warmUp));
  });

  test('starts once, and later sounds do not wait', () async {
    var started = 0;
    final engine = EngineStarter(() async => started++, warmUp: warmUp);
    // The drone and the metronome asking together share one start.
    await Future.wait([engine.ensure(), engine.ensure()]);
    final clock = Stopwatch()..start();
    await engine.ensure();
    expect(started, 1);
    expect(clock.elapsed, lessThan(warmUp));
  });

  test('tries again after a failure', () async {
    var calls = 0;
    final engine = EngineStarter(() async {
      if (calls++ == 0) throw StateError('no audio device');
    }, warmUp: Duration.zero);
    await expectLater(engine.ensure(), throwsStateError);
    await engine.ensure();
    expect(calls, 2);
  });
}
