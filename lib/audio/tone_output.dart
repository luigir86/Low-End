import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'soloud_engine.dart';

/// Plays one or more sustained sine tones at once.
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
/// Calls are expected one at a time (DroneController waits for each one to
/// finish before the next); the checks below only keep a stray overlap from
/// leaving voices nobody can stop.
class SoLoudToneOutput implements ToneOutput {
  static const _maxVoices = 4;
  static const _fade = Duration(milliseconds: 60);

  final _sources = <AudioSource>[];
  final _handles = <SoundHandle>[];
  var _gains = <double>[];
  Future<void>? _ready;

  SoLoud get _soloud => SoLoud.instance;

  /// Starts the engine and loads the voices, once; tried again on the next
  /// call if it failed.
  Future<void> _ensureReady() => _ready ??= _init().catchError((Object error) {
    _ready = null;
    throw error;
  });

  Future<void> _init() async {
    await ensureSoLoud();
    while (_sources.length < _maxVoices) {
      _sources.add(await _soloud.loadWaveform(WaveForm.sin, false, 1, 0));
    }
  }

  @override
  Future<void> play(
    List<double> frequencies,
    List<double> gains,
    double volume,
  ) async {
    assert(frequencies.length <= _maxVoices);
    assert(gains.length == frequencies.length);
    await _ensureReady();
    final retune = _handles.length == frequencies.length;
    if (!retune) {
      await stop();
      // Another call may have started voices while this one waited.
      if (_handles.isNotEmpty) _stopNow();
    }
    _gains = gains;
    for (var i = 0; i < frequencies.length; i++) {
      _soloud.setWaveformFreq(_sources[i], frequencies[i]);
      if (!retune) {
        final handle = _soloud.play(_sources[i], volume: 0, looping: true);
        _handles.add(handle);
      }
    }
    setVolume(volume);
  }

  @override
  void setVolume(double volume) {
    // Divide by the number of voices so stacked tones never clip.
    final perVoice = _handles.isEmpty ? 0.0 : volume / _handles.length;
    for (var i = 0; i < _handles.length; i++) {
      final gain = i < _gains.length ? _gains[i] : 1.0;
      _soloud.fadeVolume(_handles[i], perVoice * gain, _fade);
    }
  }

  @override
  Future<void> stop() async {
    if (_stopNow() > 0) {
      // Let the fade finish so stopping does not click.
      await Future<void>.delayed(_fade);
    }
  }

  /// Fades out and forgets every voice; returns how many there were.
  int _stopNow() {
    final handles = List.of(_handles);
    _handles.clear();
    for (final h in handles) {
      _soloud.fadeVolume(h, 0, _fade);
      _soloud.scheduleStop(h, _fade);
    }
    return handles.length;
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
