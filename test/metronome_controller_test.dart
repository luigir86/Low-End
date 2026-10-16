import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/click_output.dart';
import 'package:low_end/audio/click_sound.dart';
import 'package:low_end/audio/loop_transport.dart';
import 'package:low_end/features/metronome/metronome_controller.dart';
import 'package:low_end/features/metronome/time_signature.dart';

/// Number of samples in the WAV data of [wav] (16-bit mono).
int _samples(Uint8List wav) => (wav.length - 44) ~/ 2;

/// The sample at [index] of [wav], from -1 to 1.
double _at(Uint8List wav, int index) =>
    ByteData.sublistView(wav).getInt16(44 + index * 2, Endian.little) / 32768;

void main() {
  late SilentClickOutput output;
  late MetronomeController metronome;

  setUp(() {
    output = SilentClickOutput();
    metronome = MetronomeController(output);
  });

  test('starts at 80 BPM in 4/4 and loops one bar of four clicks', () async {
    expect(metronome.bpm, 80);
    await metronome.start();
    expect(metronome.isPlaying, isTrue);
    final bar = output.bar!;
    // 80 BPM: a beat is 0.75 s, a bar 3 s.
    expect(_samples(bar), 3 * ClickSound.sampleRate);
    final beat = ClickSound.sampleRate * 3 ~/ 4;
    for (var b = 0; b < 4; b++) {
      // A click right after each beat starts, silence half way through.
      final peak = [for (var i = 0; i < 400; i++) _at(bar, b * beat + i).abs()]
          .reduce((a, c) => a > c ? a : c);
      expect(peak, greaterThan(0.3), reason: 'beat $b');
      expect(_at(bar, b * beat + beat ~/ 2), 0, reason: 'between beats');
    }

    await metronome.stop();
    expect(output.bar, isNull);
  });

  test('the first beat is a little higher than the others', () {
    double zeroCrossingsPerSecond(Float64List s) {
      var n = 0;
      for (var i = 1; i < s.length ~/ 2; i++) {
        if ((s[i - 1] < 0) != (s[i] < 0)) n++;
      }
      return n / (s.length / 2 / ClickSound.sampleRate) / 2;
    }

    final accent = zeroCrossingsPerSecond(ClickSound.click(accent: true));
    final plain = zeroCrossingsPerSecond(ClickSound.click(accent: false));
    expect(accent, greaterThan(plain));
    // Neither shrill: around 1 kHz at most.
    expect(accent, lessThan(1600));
  });

  test('keeps the tempo between 30 and 250 BPM', () {
    metronome.setBpm(10);
    expect(metronome.bpm, MetronomeController.minBpm);
    metronome.setBpm(400);
    expect(metronome.bpm, MetronomeController.maxBpm);
    metronome.step(-1);
    expect(metronome.bpm, 249);
  });

  test('TAP sets the tempo from the average of the latest taps', () {
    const half = Duration(milliseconds: 500);
    metronome.tap(Duration.zero);
    expect(metronome.bpm, 80, reason: 'one tap is not a tempo yet');
    metronome.tap(half);
    expect(metronome.bpm, 120);
    metronome.tap(half * 2 + const Duration(milliseconds: 20));
    metronome.tap(half * 3);
    expect(metronome.bpm, 120, reason: 'a slightly late tap is averaged');
  });

  test('a pause between taps starts a new count', () {
    metronome.tap(Duration.zero);
    metronome.tap(const Duration(milliseconds: 500));
    expect(metronome.bpm, 120);
    // Three seconds later, two taps 1 s apart: 60 BPM, not a mix.
    metronome.tap(const Duration(milliseconds: 3500));
    metronome.tap(const Duration(milliseconds: 4500));
    expect(metronome.bpm, 60);
  });

  test('changing the tempo while playing keeps the beat going', () async {
    await metronome.start();
    final plays = output.plays;
    metronome.setBpm(100);
    await pumpEventQueue();
    expect(output.plays, plays + 1);
    expect(_samples(output.bar!), (ClickSound.sampleRate * 2.4).round());
    expect(metronome.isPlaying, isTrue);
  });

  test(
    'quick tempo changes rebuild the bar only as fast as the engine',
    () async {
      await metronome.start();
      final slow = _SlowClickOutput();
      final m = MetronomeController(slow);
      await m.start();
      for (var i = 0; i < 20; i++) {
        m.step(1);
      }
      await slow.drain();
      // One rebuild under way, then one with all the rest: not twenty.
      expect(slow.plays, lessThanOrEqualTo(3));
      expect(_samples(slow.bar!), ClickSound.sampleRate * 60 * 4 ~/ 100);
    },
  );

  test(
    'always starts from the first beat, even if the screen ran ahead',
    () async {
      final slow = _SlowClickOutput();
      final m = MetronomeController(slow);
      await m.start();
      expect(slow.startAt, Duration.zero);
    },
  );

  test('holding + or − lands on multiples of 5, then 10', () {
    metronome.setBpm(83);
    metronome.nudge(1, 5);
    expect(metronome.bpm, 85);
    metronome.nudge(1, 5);
    expect(metronome.bpm, 90);
    metronome.nudge(-1, 10);
    expect(metronome.bpm, 80);
    metronome.setBpm(33);
    metronome.nudge(-1, 5);
    expect(metronome.bpm, 30);
    metronome.nudge(-1, 5);
    expect(metronome.bpm, 30);
  });

  test('a bar follows the time signature', () async {
    metronome.setBpm(60);
    await metronome.start();
    metronome.setSignature(TimeSignature.sixEight);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // Six pulses of one second.
    expect(metronome.beatsPerBar, 6);
    expect(_samples(output.bar!), 6 * ClickSound.sampleRate);
    // A new bar starts from its "one".
    expect(output.startAt, Duration.zero);
  });

  test('6/8 and 3/4 differ in where the strong pulses fall', () {
    List<int> accents(TimeSignature s) => [
      for (var b = 0; b < s.beats; b++) s.accent(b),
    ];
    expect(accents(TimeSignature.threeFour), [0, 2, 2]);
    expect(accents(TimeSignature.sixEight), [0, 2, 2, 1, 2, 2]);
    expect(accents(TimeSignature.sevenEight), [0, 2, 1, 2, 1, 2, 2]);
    expect(TimeSignature.sixEight.feel, '3 + 3');
    expect(TimeSignature.threeFour.feel, '3');
  });

  test('a failure to start is reported, not thrown', () async {
    final m = MetronomeController(_FailingClickOutput());
    await m.start();
    expect(m.isPlaying, isFalse);
    expect(m.audioFailed, isTrue);
  });
}

class _SlowClickOutput extends SilentClickOutput {
  @override
  Future<LoopStart> play(Uint8List barWav, {Duration? startAt}) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return super.play(barWav, startAt: startAt);
  }

  Future<void> drain() =>
      Future<void>.delayed(const Duration(milliseconds: 50));
}

class _FailingClickOutput extends SilentClickOutput {
  @override
  Future<LoopStart> play(Uint8List barWav, {Duration? startAt}) =>
      Future.error(StateError('no audio device'));
}
