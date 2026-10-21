import 'dart:math' as math;
import 'dart:typed_data';

import 'click_sound.dart';
import 'piano_sound.dart' show Stereo;

/// A small room around the piano: Freeverb, by Jezar at Dreampoint (public
/// domain), the reverb of many a free synth. The Salamander was recorded
/// with the microphones close to the strings, dry; a little of a room
/// makes it sound like a piano in a room, not inside one.
class Freeverb {
  Freeverb({
    required double room,
    required double damp,
    required this.wet,
    required this.preDelay,
  }) : _feedback = room * 0.28 + 0.7,
       _damp = damp * 0.4;

  /// The room of Harmony: small, a little soft at the top, the reflections
  /// starting 15 ms after the note, so its attack stays clear.
  factory Freeverb.room() => Freeverb(
    room: 0.4,
    damp: 0.5,
    wet: 0.14,
    preDelay: const Duration(milliseconds: 15),
  );

  final double wet;
  final Duration preDelay;
  final double _feedback, _damp;

  // The original tuning, in samples at 44.1 kHz, and the spread between
  // the left and the right channel.
  static const _combs = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617];
  static const _allPasses = [556, 441, 341, 225];
  static const _spread = 23;
  static const _inputGain = 0.015;

  /// [dry] with the room added, as a loop: the room's sound at the end of
  /// it carries on into its start, as when it plays round and round.
  Stereo loop(Stereo dry) {
    final n = dry.left.length;
    // Run over the end of the loop first, so the room is already full of
    // it when the loop starts.
    final lead = math.min(n, ClickSound.sampleRate * 2);
    final input = Float64List(lead + n);
    for (var i = 0; i < lead; i++) {
      final j = n - lead + i;
      input[i] = (dry.left[j] + dry.right[j]) / 2;
    }
    for (var i = 0; i < n; i++) {
      input[lead + i] = (dry.left[i] + dry.right[i]) / 2;
    }
    return _mix(dry, input, lead);
  }

  /// [dry] with the room added, from silence.
  Stereo run(Stereo dry) {
    final n = dry.left.length;
    final input = Float64List(n);
    for (var i = 0; i < n; i++) {
      input[i] = (dry.left[i] + dry.right[i]) / 2;
    }
    return _mix(dry, input, 0);
  }

  /// The dry sound plus the room made from [input], whose first [lead]
  /// samples only fill the room.
  Stereo _mix(Stereo dry, Float64List input, int lead) {
    final n = dry.left.length;
    final scale = ClickSound.sampleRate / 44100;
    final delay = preDelay.inMicroseconds * ClickSound.sampleRate ~/ 1000000;
    final left = Float64List.fromList(dry.left);
    final right = Float64List.fromList(dry.right);
    for (final (channel, spread) in [(left, 0), (right, _spread)]) {
      final combs = [
        for (final c in _combs) _Comb(((c + spread) * scale).round()),
      ];
      final allPasses = [
        for (final a in _allPasses) _AllPass(((a + spread) * scale).round()),
      ];
      for (var i = 0; i < input.length; i++) {
        final x = i >= delay ? input[i - delay] * _inputGain : 0.0;
        var y = 0.0;
        for (final c in combs) {
          y += c.process(x, _feedback, _damp);
        }
        for (final a in allPasses) {
          y = a.process(y);
        }
        if (i >= lead) channel[i - lead] += y * wet * 3;
      }
    }
    assert(left.length == n);
    return (left: left, right: right);
  }
}

class _Comb {
  _Comb(int size) : _buffer = Float64List(size);

  final Float64List _buffer;
  var _index = 0;
  var _store = 0.0;

  double process(double input, double feedback, double damp) {
    final output = _buffer[_index];
    _store = output * (1 - damp) + _store * damp;
    _buffer[_index] = input + _store * feedback;
    if (++_index == _buffer.length) _index = 0;
    return output;
  }
}

class _AllPass {
  _AllPass(int size) : _buffer = Float64List(size);

  final Float64List _buffer;
  var _index = 0;

  double process(double input) {
    final buffered = _buffer[_index];
    _buffer[_index] = input + buffered * 0.5;
    if (++_index == _buffer.length) _index = 0;
    return buffered - input;
  }
}
