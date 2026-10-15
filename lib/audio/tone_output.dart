import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'drone_sound.dart';
import 'soloud_engine.dart';

/// Plays one or more sustained tones at once, as one sound.
///
/// Kept behind an interface so the rest of the app can be tested without a
/// real audio device.
abstract class ToneOutput {
  /// Starts (or retunes, if already playing) the given frequencies in Hz.
  /// [gains] holds one relative volume per frequency, 0 to 1.
  Future<void> play(
    List<double> frequencies,
    List<double> gains,
    double volume,
  );

  /// Changes the overall volume, 0 to 1, of the tones already playing.
  void setVolume(double volume);

  Future<void> stop();
}

/// [ToneOutput] backed by the SoLoud audio engine.
///
/// Plays the tone made by DroneSound as a seamless loop. Calls are expected
/// one at a time (DroneController waits for each one to finish before the
/// next).
class SoLoudToneOutput implements ToneOutput {
  static const _fade = Duration(milliseconds: 80);

  AudioSource? _source;
  SoundHandle? _handle;
  List<double> _frequencies = const [];
  List<double> _gains = const [];

  SoLoud get _soloud => SoLoud.instance;

  @override
  Future<void> play(
    List<double> frequencies,
    List<double> gains,
    double volume,
  ) async {
    assert(gains.length == frequencies.length);
    await ensureSoLoud();
    if (_handle != null &&
        listEquals(frequencies, _frequencies) &&
        listEquals(gains, _gains)) {
      setVolume(volume);
      return;
    }
    // Building the tone takes a moment: away from the screen's thread.
    final wav = await Isolate.run(() => DroneSound.loopWav(frequencies, gains));
    final source = await _soloud.loadMem('drone.wav', wav);
    final handle = _soloud.play(source, volume: 0, looping: true);
    // The new tone fades in while the old one fades out: no click, no gap.
    _soloud.fadeVolume(handle, volume, _fade);
    final oldHandle = _handle, oldSource = _source;
    _handle = handle;
    _source = source;
    _frequencies = List.of(frequencies);
    _gains = List.of(gains);
    await _release(oldHandle, oldSource);
  }

  @override
  void setVolume(double volume) {
    final handle = _handle;
    if (handle != null) _soloud.fadeVolume(handle, volume, _fade);
  }

  @override
  Future<void> stop() async {
    final handle = _handle, source = _source;
    _handle = null;
    _source = null;
    _frequencies = const [];
    await _release(handle, source);
  }

  /// Fades [handle] out, then stops it and frees [source].
  Future<void> _release(SoundHandle? handle, AudioSource? source) async {
    if (handle != null) {
      _soloud.fadeVolume(handle, 0, _fade);
      _soloud.scheduleStop(handle, _fade);
      // Let the fade finish so stopping does not click.
      await Future<void>.delayed(_fade);
    }
    if (source != null) await _soloud.disposeSource(source);
  }
}

/// [ToneOutput] that makes no sound; used where audio is unavailable.
@visibleForTesting
class SilentToneOutput implements ToneOutput {
  List<double> frequencies = const [];
  double volume = 0;

  @override
  Future<void> play(List<double> f, List<double> gains, double v) async {
    frequencies = f;
    volume = v;
  }

  @override
  void setVolume(double v) => volume = v;

  @override
  Future<void> stop() async => frequencies = const [];
}
