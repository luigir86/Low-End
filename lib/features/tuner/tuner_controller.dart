import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../audio/mic_input.dart';
import '../../audio/pitch_detector.dart';
import 'tunings.dart';

enum TunerStatus { idle, starting, listening, permissionDenied, failed }

/// Listens to the microphone and keeps the latest detected frequency.
class TunerController extends ChangeNotifier {
  TunerController(this._mic, {this.sampleRate = 16000});

  final MicInput _mic;
  final int sampleRate;

  late final _detector = PitchDetector(sampleRate: sampleRate);

  /// One reading every 50 ms.
  late final _hop = sampleRate ~/ 20;

  /// Readings in a row without a note before the display clears (about
  /// half a second), so the needle does not flicker as a note decays.
  static const _holdReadings = 10;

  late final _window = Float64List(_detector.windowSize);
  var _filled = 0;
  var _sinceReading = 0;
  final _recent = <double>[];
  var _missed = 0;

  StreamSubscription<Float64List>? _subscription;
  var _status = TunerStatus.idle;
  double? _frequency;
  // Chromatic by default: the tuner names whatever note it hears.
  Tuning? _tuning;

  TunerStatus get status => _status;
  bool get isListening =>
      _status == TunerStatus.listening || _status == TunerStatus.starting;

  /// The detected frequency in Hz, smoothed, or null when no note is heard.
  double? get frequency => _frequency;

  /// The chosen tuning, or null for chromatic mode (any note).
  Tuning? get tuning => _tuning;

  void setTuning(Tuning? tuning) {
    _tuning = tuning;
    notifyListeners();
  }

  Future<void> start() async {
    if (isListening) return;
    _status = TunerStatus.starting;
    notifyListeners();
    try {
      if (!await _mic.requestPermission()) {
        _status = TunerStatus.permissionDenied;
        notifyListeners();
        return;
      }
      final samples = await _mic.start(sampleRate);
      if (_status != TunerStatus.starting) {
        // Stopped while waiting for the microphone.
        await _mic.stop();
        return;
      }
      _subscription = samples.listen(_onSamples);
      _status = TunerStatus.listening;
    } catch (error) {
      debugPrint('Tuner could not start: $error');
      _status = TunerStatus.failed;
    }
    notifyListeners();
  }

  Future<void> stop() async {
    if (_status == TunerStatus.idle) return;
    final subscription = _subscription;
    _subscription = null;
    _status = TunerStatus.idle;
    _reset();
    notifyListeners();
    if (subscription != null) {
      await _mic.stop();
      await subscription.cancel();
    }
  }

  Future<void> toggle() => isListening ? stop() : start();

  void _reset() {
    _filled = 0;
    _sinceReading = 0;
    _recent.clear();
    _missed = 0;
    _frequency = null;
  }

  void _onSamples(Float64List samples) {
    // Slide the window along, keeping the newest samples at its end.
    final size = _window.length;
    if (samples.length >= size) {
      _window.setRange(0, size, samples, samples.length - size);
      _filled = size;
    } else {
      final keep = size - samples.length;
      _window.setRange(0, keep, _window, samples.length);
      _window.setRange(keep, size, samples);
      _filled = (_filled + samples.length).clamp(0, size);
    }
    _sinceReading += samples.length;
    if (_filled < size || _sinceReading < _hop) return;
    _sinceReading = 0;
    _addReading(_detector.detect(_window));
  }

  void _addReading(double? hz) {
    final previous = _frequency;
    if (hz == null) {
      if (++_missed >= _holdReadings) {
        _recent.clear();
        _frequency = null;
      }
    } else {
      _missed = 0;
      _recent.add(hz);
      if (_recent.length > 3) _recent.removeAt(0);
      // The median of the last readings drops one-off octave jumps.
      final sorted = List.of(_recent)..sort();
      _frequency = sorted[sorted.length ~/ 2];
    }
    if (_frequency != previous) notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    if (_status != TunerStatus.idle) _mic.stop();
    super.dispose();
  }
}
