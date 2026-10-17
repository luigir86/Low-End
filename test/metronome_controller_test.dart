import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/click_output.dart';
import 'package:low_end/audio/click_sound.dart';
import 'package:low_end/audio/loop_transport.dart';
import 'package:low_end/features/metronome/feel.dart';
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

  test('counts down the wait for the piano\'s bar line', () async {
    await metronome.start();
    // Nothing to wait for: the click came in at once.
    expect(metronome.waitLeft, isNull);
    await metronome.stop();
    expect(metronome.waitLeft, isNull);

    output.delay = const Duration(seconds: 2);
    await metronome.start();
    final left = metronome.waitLeft!;
    expect(left, greaterThan(const Duration(milliseconds: 1500)));
    expect(left, lessThanOrEqualTo(const Duration(seconds: 2)));
    await metronome.stop();
    expect(metronome.waitLeft, isNull);
  });

  test('the "one" is higher than the rest, and a click is short and clean', () {
    double peak(Float64List s) =>
        s.map((v) => v.abs()).reduce((a, c) => a > c ? a : c);
    // Crossings of zero in the first 20 ms: the pitch.
    int crossings(Float64List s) {
      var n = 0;
      for (var i = 1; i < ClickSound.sampleRate ~/ 50; i++) {
        if ((s[i - 1] < 0) != (s[i] < 0)) n++;
      }
      return n;
    }

    final accent = ClickSound.click(accent: true);
    final group = ClickSound.click(accent: false, hz: ClickSound.groupHz);
    final plain = ClickSound.click(accent: false);
    expect(crossings(accent), greaterThan(crossings(group)));
    expect(crossings(group), greaterThan(crossings(plain)));
    // It never clips, and ends well before the next beat of 250 BPM.
    for (final s in [accent, group, plain]) {
      expect(peak(s), lessThan(0.95));
      expect(s.length, lessThan(ClickSound.sampleRate * 60 ~/ 250));
    }
    // The skip note of the swing is the plain click, softer.
    final skip = ClickSound.skip();
    expect(skip.length, plain.length);
    expect(peak(skip), lessThan(peak(plain)));
    expect(peak(skip), greaterThan(0.2));
  });

  group('the feel', () {
    // 4/4 at 60: a beat is a second, so a third and two thirds are easy.
    int beat() => ClickSound.sampleRate;
    double energy(Float64List bar, int from, int length) {
      var sum = 0.0;
      for (var i = from; i < from + length; i++) {
        sum += bar[i] * bar[i];
      }
      return sum;
    }

    Float64List samples(MetronomeFeel feel, [TimeSignature? s]) {
      final wav = ClickSound.bar(
        bpm: 60,
        signature: s ?? TimeSignature.fourFour,
        feel: feel,
      );
      return Float64List.fromList([
        for (var i = 44; i < wav.length; i += 2)
          ((wav[i] | (wav[i + 1] << 8)).toSigned(16)) / 32767,
      ]);
    }

    test('straight sounds only on the beats', () {
      final bar = samples(MetronomeFeel.straight);
      final skip = beat() * 2 ~/ 3;
      for (var b = 0; b < 4; b++) {
        expect(energy(bar, b * beat() + skip, 200), 0, reason: 'beat $b');
      }
    });

    test('swing skips after 2 and 4, softly', () {
      final bar = samples(MetronomeFeel.swing);
      final skip = beat() * 2 ~/ 3;
      expect(energy(bar, 0 * beat() + skip, 200), 0);
      expect(energy(bar, 1 * beat() + skip, 200), greaterThan(0));
      expect(energy(bar, 2 * beat() + skip, 200), 0);
      expect(energy(bar, 3 * beat() + skip, 200), greaterThan(0));
      // The skip note is softer than the beat before it.
      expect(
        energy(bar, beat() + skip, 2000),
        lessThan(energy(bar, beat(), 2000)),
      );
      // The beats themselves are where they were.
      final straight = samples(MetronomeFeel.straight);
      expect(energy(bar, 0, beat() ~/ 2), energy(straight, 0, beat() ~/ 2));
    });

    test('a bar of one beat swings too, and the loop never clips', () {
      final bar = samples(MetronomeFeel.swing, TimeSignature.oneOne);
      expect(energy(bar, beat() * 2 ~/ 3, 200), greaterThan(0));
      for (final feel in MetronomeFeel.values) {
        final loop = samples(feel);
        expect(loop.every((v) => v.abs() <= 0.96), isTrue);
      }
    });

    test('bars in eighths are always straight', () {
      expect(
        samples(MetronomeFeel.swing, TimeSignature.sixEight),
        samples(MetronomeFeel.straight, TimeSignature.sixEight),
      );
    });

    test('there are two feels: straight and swing', () {
      expect(MetronomeFeel.values, [
        MetronomeFeel.straight,
        MetronomeFeel.swing,
      ]);
    });

    test('the controller plays the feel, keeping the bar going', () async {
      expect(metronome.feel, MetronomeFeel.straight);
      await metronome.start();
      final straight = output.bar!;
      metronome.setFeel(MetronomeFeel.swing);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(metronome.feel, MetronomeFeel.swing);
      expect(output.bar, isNot(straight));
      // Same length, and it carries on rather than starting again.
      expect(output.bar!.length, straight.length);
      expect(output.startAt, isNull);
      // Not for the bars in eighths.
      metronome.setSignature(TimeSignature.sixEight);
      expect(metronome.feelApplies, isFalse);
    });
  });

  group('the first sound has time to come up', () {
    test('some of the silence at the end of the bar is played first', () {
      final bar = ClickSound.bar(bpm: 80);
      // 4/4 at 80: a click lasts 60 ms of a beat of 750: plenty of room.
      expect(
        SoLoudClickOutput.preRollFor(bar),
        const Duration(milliseconds: 120),
      );
      // The swing keeps it too: its last skip note ends well before the end.
      expect(
        SoLoudClickOutput.preRollFor(
          ClickSound.bar(bpm: 80, feel: MetronomeFeel.swing),
        ),
        const Duration(milliseconds: 120),
      );
    });

    test('never into a click: less of it when beats are crowded', () {
      // 250 BPM, a beat of 240 ms: the click is over in 60, and the swing's
      // skip note falls at 160 and ends at 220: 20 ms of silence is not
      // enough to play any.
      final bar = ClickSound.bar(bpm: 250, feel: MetronomeFeel.swing);
      expect(SoLoudClickOutput.preRollFor(bar), Duration.zero);
    });
  });

  test('keeps the tempo between 30 and 250 BPM in 4/4', () {
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
    // 60 dotted quarters a minute: two beats of a second, six clicks.
    expect(metronome.beatsPerBar, 6);
    expect(metronome.pulseBpm, 180);
    expect(_samples(output.bar!), 2 * ClickSound.sampleRate);
    expect(
      metronome.barLength.inMicroseconds,
      closeTo(const Duration(seconds: 2).inMicroseconds, 10),
    );
    // A new bar starts from its "one".
    expect(output.startAt, Duration.zero);
  });

  test('1/1 is a bar of one click, every click the "one"', () async {
    metronome.setBpm(120);
    metronome.setSignature(TimeSignature.oneOne);
    expect(TimeSignature.all.first, TimeSignature.oneOne);
    expect(metronome.beatsPerBar, 1);
    expect(metronome.pulseBpm, 120);
    expect(metronome.barLength, const Duration(milliseconds: 500));
    await metronome.start();
    expect(_samples(output.bar!), ClickSound.sampleRate ~/ 2);
    // Always the "one": the whole bar is one segment, lit all the time.
    expect(metronome.beat, 0);
    expect(TimeSignature.oneOne.accent(0), 0);
    expect(TimeSignature.oneOne.label, '1/1');
  });

  group('compound bars count the dotted quarter', () {
    test('6/8, 9/8 and 12/8 at ♩. = 100 click 300 eighths a minute', () {
      for (final s in [
        TimeSignature.sixEight,
        TimeSignature.nineEight,
        TimeSignature.twelveEight,
      ]) {
        metronome.setSignature(s);
        metronome.setBpm(100);
        expect(s.compound, isTrue);
        expect(s.beatUnit, BeatUnit.dottedQuarter);
        expect(metronome.bpm, 100);
        expect(metronome.pulseBpm, 300, reason: s.label);
        final beats = s.beats ~/ 3;
        final bar = ClickSound.bar(bpm: metronome.pulseBpm, signature: s);
        expect(
          _samples(bar),
          closeTo(beats * 0.6 * ClickSound.sampleRate, s.beats),
        );
      }
    });

    test('x/4 counts the quarter and 7/8 the eighth, one click each', () {
      expect(TimeSignature.fourFour.beatUnit, BeatUnit.quarter);
      expect(TimeSignature.fiveFour.compound, isFalse);
      expect(TimeSignature.sevenEight.compound, isFalse);
      expect(TimeSignature.sevenEight.beatUnit, BeatUnit.eighth);
      metronome.setSignature(TimeSignature.sevenEight);
      metronome.setBpm(200);
      expect(metronome.pulseBpm, 200);
    });

    test('fast tempos can be set: a gigue at ♩. = 120, 7/8 up to 400', () {
      metronome.setSignature(TimeSignature.sixEight);
      metronome.setBpm(120);
      expect(metronome.bpm, 120);
      metronome.setBpm(1000);
      expect(metronome.bpm, MetronomeController.maxBpm);
      metronome.setSignature(TimeSignature.sevenEight);
      metronome.setBpm(380);
      expect(metronome.bpm, 380);
      expect(metronome.maxTempo, MetronomeController.maxEighthBpm);
      // Back to 4/4, the tempo comes within its range.
      metronome.setSignature(TimeSignature.fourFour);
      expect(metronome.bpm, MetronomeController.maxBpm);
    });

    test('TAP in 6/8 takes the taps as dotted quarters', () {
      metronome.setSignature(TimeSignature.sixEight);
      // A tap a second, as anyone taps a 6/8: ♩. = 60, not ♪ = 60.
      for (var i = 0; i < 4; i++) {
        metronome.tap(Duration(seconds: i));
      }
      expect(metronome.bpm, 60);
      expect(metronome.pulseBpm, 180);
    });

    test('a click lasts a third of the beat in 6/8', () {
      metronome.setSignature(TimeSignature.sixEight);
      metronome.setBpm(60);
      expect(metronome.pulseLength, const Duration(microseconds: 333333));
    });
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
