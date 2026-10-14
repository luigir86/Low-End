import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

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
class SoLoudToneOutput implements ToneOutput {
  static const _maxVoices = 3;
  static const _fade = Duration(milliseconds: 60);

  final _sources = <AudioSource>[];
  final _handles = <SoundHandle>[];
  var _gains = <double>[];

  SoLoud get _soloud => SoLoud.instance;

  Future<void> _ensureReady() async {
    if (!_soloud.isInitialized) await _soloud.init();
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
    await _ensureReady();
    final retune = _handles.length == frequencies.length;
    if (!retune) await stop();
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
      _soloud.fadeVolume(_handles[i], perVoice * _gains[i], _fade);
    }
  }

  @override
  Future<void> stop() async {
    final handles = List.of(_handles);
    _handles.clear();
    for (final h in handles) {
      _soloud.fadeVolume(h, 0, _fade);
      _soloud.scheduleStop(h, _fade);
    }
    if (handles.isNotEmpty) {
      // Let the fade finish so stopping does not click.
      await Future<void>.delayed(_fade);
    }
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
