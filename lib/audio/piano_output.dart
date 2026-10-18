import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../features/metronome/time_signature.dart';
import 'bar_loop_player.dart';
import 'click_sound.dart';
import 'loop_transport.dart';
import 'piano_sound.dart';

/// Plays the chords of the drone on the piano, one bar after another, in
/// time with the metronome.
///
/// Kept behind an interface so the rest of the app can be tested without a
/// real audio device.
abstract class PianoOutput {
  /// Starts looping [chords] (one per bar) in [style] at [bpm] pulses (the
  /// metronome's clicks) a minute in [signature], tuned to [a4], at
  /// [volume]; replaces what plays now.
  ///
  /// With no [startAt], a loop replacing another carries on from where the
  /// old one was, as a tempo change should; otherwise it starts that far in
  /// and, if the metronome is playing, waits for its next bar line. Says
  /// where and when it began.
  ///
  /// With [rootless], the chords have no root: their lowest note is not one.
  Future<LoopStart> play({
    required List<PianoChord> chords,
    required PianoStyle style,
    required int bpm,
    required TimeSignature signature,
    required double a4,
    required double volume,
    Duration? startAt,
    bool rootless = false,
  });

  Future<void> stop();
}

/// [PianoOutput] backed by the SoLoud audio engine.
class SoLoudPianoOutput implements PianoOutput {
  // Follows the clicks: after a change of tempo it comes back in on their
  // beat, not on its own.
  final _player = BarLoopPlayer('piano', follows: true);
  Future<PianoSamples>? _samples;

  /// Reads the recordings once.
  Future<PianoSamples> _load() =>
      _samples ??= PianoSamples.load().catchError((Object error) {
        _samples = null;
        throw error;
      });

  @override
  Future<LoopStart> play({
    required List<PianoChord> chords,
    required PianoStyle style,
    required int bpm,
    required TimeSignature signature,
    required double a4,
    required double volume,
    Duration? startAt,
    bool rootless = false,
  }) async {
    final samples = await _load();
    _player.setVolume(volume);
    // Mixing the notes takes a moment: away from the screen's thread.
    final wav = await _render(
      samples,
      chords,
      style,
      bpm,
      signature,
      a4,
      rootless,
    );
    final bar = Duration(
      microseconds:
          (ClickSound.sampleRate * 60 / bpm).round() *
          signature.beats *
          1000000 ~/
          ClickSound.sampleRate,
    );
    return _player.play(wav, bar, startAt: startAt);
  }

  /// Static, so that the closure sent to the isolate captures nothing but
  /// what it needs.
  static Future<Uint8List> _render(
    PianoSamples samples,
    List<PianoChord> chords,
    PianoStyle style,
    int bpm,
    TimeSignature signature,
    double a4,
    bool rootless,
  ) => Isolate.run(
    () => PianoSound.loopWav(
      samples: samples,
      chords: chords,
      style: style,
      bpm: bpm,
      signature: signature,
      a4: a4,
      rootless: rootless,
    ),
  );

  @override
  Future<void> stop() => _player.stop();
}

/// [PianoOutput] that makes no sound; used where audio is unavailable.
@visibleForTesting
class SilentPianoOutput implements PianoOutput {
  /// What plays now, or null when stopped.
  List<PianoChord>? chords;
  PianoStyle? style;
  int? bpm;
  TimeSignature? signature;
  Duration? startAt;
  bool rootless = false;
  double volume = 0;
  var plays = 0;

  /// How long the next start waits, as if the metronome were playing.
  Duration delay = Duration.zero;

  @override
  Future<LoopStart> play({
    required List<PianoChord> chords,
    required PianoStyle style,
    required int bpm,
    required TimeSignature signature,
    required double a4,
    required double volume,
    Duration? startAt,
    bool rootless = false,
  }) async {
    this.chords = chords;
    this.rootless = rootless;
    this.style = style;
    this.bpm = bpm;
    this.signature = signature;
    this.startAt = startAt;
    this.volume = volume;
    plays++;
    return (position: startAt ?? Duration.zero, delay: delay);
  }

  @override
  Future<void> stop() async => chords = null;
}
