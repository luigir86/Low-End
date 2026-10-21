// Prepares the piano recordings the app ships (see lib/audio/piano_sound.dart)
// from the Salamander Grand Piano V3, 44.1 kHz 16-bit WAV edition by
// Alexander Holm (public domain since 2022).
//
//   dart run tool/prepare_piano.dart <folder with A2v8.wav ...> assets/piano
//
// Each note becomes a short mono 22.05 kHz 16-bit WAV (a 44-byte header, as
// PianoSamples.decodeWav expects), levelled to the same loudness.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _notes = [
  'A2', 'C3', 'D#3', 'F#3', 'A3', 'C4', 'D#4', 'F#4', 'A4', 'C5', //
];

/// Velocity layer used (1 to 16): a medium-soft touch.
const _layer = 8;

/// How much of each note to keep, and how long the fade-out at its end.
const _keep = 3.6;
const _fade = 1.0;

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: dart run tool/prepare_piano.dart <in> <out>');
    exit(64);
  }
  final out = Directory(args[1])..createSync(recursive: true);
  for (final note in _notes) {
    final file = File('${args[0]}/${note}v$_layer.wav');
    final (rate, mono) = _readWav(file.readAsBytesSync());
    final half = _decimate(mono, rate);
    final trimmed = _trim(half);
    final name = note.replaceAll('#', 's');
    File('${out.path}/$name.wav').writeAsBytesSync(_writeWav(trimmed));
    stdout.writeln('$name: ${trimmed.length} samples');
  }
}

(int, Float64List) _readWav(Uint8List bytes) {
  final view = ByteData.sublistView(bytes);
  var at = 12;
  var channels = 1, rate = 44100;
  int? dataAt, dataLength;
  while (at + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(at, at + 4));
    final size = view.getUint32(at + 4, Endian.little);
    if (id == 'fmt ') {
      channels = view.getUint16(at + 10, Endian.little);
      rate = view.getUint32(at + 12, Endian.little);
      final bits = view.getUint16(at + 22, Endian.little);
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

/// Halves the sample rate (44.1 kHz to 22.05 kHz) with a windowed-sinc
/// low-pass at 9.5 kHz.
Float64List _decimate(Float64List x, int rate) {
  if (rate != 44100) throw StateError('44.1 kHz expected, got $rate');
  const taps = 63, half = taps ~/ 2;
  final h = List<double>.generate(taps, (i) {
    final n = i - half;
    final fc = 9500 / rate;
    final sinc = n == 0
        ? 2 * fc
        : math.sin(2 * math.pi * fc * n) / (math.pi * n);
    final window = 0.54 - 0.46 * math.cos(2 * math.pi * i / (taps - 1));
    return sinc * window;
  });
  final out = Float64List(x.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    var sum = 0.0;
    for (var k = 0; k < taps; k++) {
      final j = i * 2 + k - half;
      if (j >= 0 && j < x.length) sum += h[k] * x[j];
    }
    out[i] = sum;
  }
  return out;
}

/// Starts just before the attack, keeps [_keep] seconds, fades the end and
/// levels the note to a common loudness.
Float64List _trim(Float64List x) {
  const rate = 22050;
  var peak = 0.0;
  for (final v in x) {
    peak = math.max(peak, v.abs());
  }
  var start = 0;
  while (start < x.length && x[start].abs() < peak * 0.02) {
    start++;
  }
  start = math.max(0, start - (rate * 0.004).round());
  final length = math.min(x.length - start, (rate * _keep).round());
  final y = Float64List.fromList(x.sublist(start, start + length));
  final fade = (rate * _fade).round();
  for (var i = 0; i < fade; i++) {
    final t = i / fade;
    y[length - fade + i] *= 0.5 * (1 + math.cos(math.pi * t));
  }
  // Level by the energy of the first second (the body of the note).
  var energy = 0.0;
  final body = math.min(rate, length);
  for (var i = 0; i < body; i++) {
    energy += y[i] * y[i];
  }
  final rms = math.sqrt(energy / body);
  final gain = 0.14 / rms;
  for (var i = 0; i < length; i++) {
    y[i] *= gain;
  }
  var top = 0.0;
  for (final v in y) {
    top = math.max(top, v.abs());
  }
  // Never clip, whatever the note.
  if (top > 0.9) {
    for (var i = 0; i < length; i++) {
      y[i] *= 0.9 / top;
    }
  }
  return y;
}

Uint8List _writeWav(Float64List samples) {
  const rate = 22050;
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
    final s = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(44 + i * 2, s, Endian.little);
  }
  return bytes.buffer.asUint8List();
}
