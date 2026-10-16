// Prepares the drum strokes the metronome ships (see lib/audio/drum_kit.dart)
// from the Versilian Community Sample Library (VCSL), released under
// CC0 1.0 (public domain) by Versilian Studios: https://github.com/sgossner/VCSL
//
//   dart run tool/prepare_drums.dart <folder with the VCSL files> assets/drums
//
// The folder holds these files from the library (flat, as downloaded):
//   Membranophones/Struck Membranophones/Bass Drum 1/BDrumNew_hit_v2_rr1_Sum.wav
//   Membranophones/Struck Membranophones/Snare Drum, Modern 1/Snare2_HitSN_v3_rr1_Mid.wav
//   Idiophones/Struck Idiophones/Hi-Hat Cymbal/HiHat_Close_rr1_Mid.wav
//   Idiophones/Struck Idiophones/Suspended Cymbal 1/susCymb1_hit_stick_mp1.wav
//   Idiophones/Struck Idiophones/Suspended Cymbal 1/susCymb1_hit_bell_mf1.wav
//
// Each stroke becomes a short mono 44.1 kHz 16-bit WAV (a 44-byte header, as
// DrumKit.decode expects), starting at its attack, faded at the end and
// levelled to a common peak.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// name: source file, how much to keep (ms), how long the fade-out at its
/// end is (ms), and the peak it is levelled to (0 to 1).
const _strokes = <String, (String, int, int, double)>{
  // The stick on a suspended cymbal: the ride.
  'ride': ('susCymb1_hit_stick_mp1.wav', 320, 120, 0.9),
  // The same cymbal on its bell, for the "one".
  'bell': ('susCymb1_hit_bell_mf1.wav', 360, 140, 0.9),
  // A shorter ride, for the skip note of the swing and the shuffle.
  'ghost': ('susCymb1_hit_stick_mp1.wav', 150, 70, 0.9),
  'kick': ('BDrumNew_hit_v2_rr1_Sum.wav', 330, 120, 0.9),
  'snare': ('Snare2_HitSN_v3_rr1_Mid.wav', 230, 100, 0.9),
  // The hi-hat closing with the foot.
  'chick': ('HiHat_Close_rr1_Mid.wav', 130, 70, 0.9),
};

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: dart run tool/prepare_drums.dart <in> <out>');
    exit(64);
  }
  final out = Directory(args[1])..createSync(recursive: true);
  for (final entry in _strokes.entries) {
    final (file, keep, fade, peak) = entry.value;
    final (rate, mono) = _readWav(File('${args[0]}/$file').readAsBytesSync());
    final stroke = _cut(mono, rate, keep, fade, peak);
    File('${out.path}/${entry.key}.wav')
        .writeAsBytesSync(_writeWav(stroke, rate));
    stdout.writeln('${entry.key}: ${stroke.length} samples at $rate Hz');
  }
}

(int, Float64List) _readWav(Uint8List bytes) {
  final view = ByteData.sublistView(bytes);
  var at = 12;
  var channels = 1, rate = 44100, bits = 16;
  int? dataAt, dataLength;
  while (at + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(at, at + 4));
    final size = view.getUint32(at + 4, Endian.little);
    if (id == 'fmt ') {
      channels = view.getUint16(at + 10, Endian.little);
      rate = view.getUint32(at + 12, Endian.little);
      bits = view.getUint16(at + 22, Endian.little);
      if (bits != 16) throw StateError('16-bit WAV expected, got $bits');
    } else if (id == 'data') {
      dataAt = at + 8;
      dataLength = size;
      break;
    }
    at += 8 + size + (size.isOdd ? 1 : 0);
  }
  if (dataAt == null) throw StateError('no data chunk');
  final frames = dataLength! ~/ (2 * channels);
  final mono = Float64List(frames);
  for (var i = 0; i < frames; i++) {
    var sum = 0.0;
    for (var c = 0; c < channels; c++) {
      sum += view.getInt16(dataAt + (i * channels + c) * 2, Endian.little);
    }
    mono[i] = sum / channels / 32768;
  }
  return (rate, mono);
}

/// Starts a millisecond before the attack, keeps [keep] ms, fades the last
/// [fade] ms and levels the peak to [peak].
Float64List _cut(Float64List x, int rate, int keep, int fade, double peak) {
  var top = 0.0;
  for (final v in x) {
    top = math.max(top, v.abs());
  }
  var start = 0;
  while (start < x.length && x[start].abs() < top * 0.05) {
    start++;
  }
  start = math.max(0, start - rate ~/ 1000);
  final length = math.min(x.length - start, rate * keep ~/ 1000);
  final y = Float64List.fromList(x.sublist(start, start + length));
  final fadeLength = math.min(length, rate * fade ~/ 1000);
  for (var i = 0; i < fadeLength; i++) {
    final t = i / fadeLength;
    y[length - fadeLength + i] *= 0.5 * (1 + math.cos(math.pi * t));
  }
  var cut = 0.0;
  for (final v in y) {
    cut = math.max(cut, v.abs());
  }
  for (var i = 0; i < length; i++) {
    y[i] *= peak / cut;
  }
  return y;
}

Uint8List _writeWav(Float64List samples, int rate) {
  final data = samples.length * 2;
  final bytes = ByteData(44 + data);
  void ascii(int at, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes.setUint8(at + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + data, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, rate, Endian.little);
  bytes.setUint32(28, rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, data, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    bytes.setInt16(
      44 + i * 2,
      (samples[i].clamp(-1.0, 1.0) * 32767).round(),
      Endian.little,
    );
  }
  return bytes.buffer.asUint8List();
}
