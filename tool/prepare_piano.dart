// Prepares the piano recordings the app ships (see lib/audio/piano_sound.dart)
// from the Salamander Grand Piano V3 by Alexander Holm (public domain since
// 2022), 48 kHz 24-bit, as published at
// https://github.com/sfzinstruments/SalamanderGrandPiano (FLAC).
//
// 1. Decode the FLAC files needed to WAV, keeping 24 bits, e.g. with ffmpeg:
//      ffmpeg -i Samples/C4v8.flac -c:a pcm_s24le wav/C4v8.wav
//    (the notes of [_roots] in layers 5, 8 and 11, and rel16 to rel51).
// 2. dart run tool/prepare_piano.dart wav out
// 3. Encode every WAV in out to FLAC at the highest compression, e.g.
//      ffmpeg -i out/C4v8L.wav -compression_level 12 assets/piano/C4v8L.flac
//
// It prints how far each recording is from equal temperament, for
// PianoSamples.cents.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _rate = 48000;

/// The notes recorded, a minor third apart, from C2 to C5.
const _roots = [
  'C2', 'D#2', 'F#2', 'A2', 'C3', 'D#3', 'F#3', 'A3', 'C4', 'D#4', 'F#4', //
  'A4', 'C5',
];

/// Velocity layers kept (of 16), and how much of each: the normal one long
/// enough for a slow bar, the soft and the firm one for short strokes.
const _layers = {5: 4.0, 8: 10.0, 11: 4.0};

/// The dampers falling back on the strings, for the keys Harmony plays
/// (C2 to B4): rel1 is A0.
const _lowestRelease = 36, _highestRelease = 71;

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: dart run tool/prepare_piano.dart <in> <out>');
    exit(64);
  }
  final out = Directory(args[1])..createSync(recursive: true);
  stdout.writeln(
    'note: cents from equal temperament, gain to the common level',
  );
  for (final name in _roots) {
    final layers = <int, List<Float64List>>{};
    for (final MapEntry(key: v, value: seconds) in _layers.entries) {
      final stereo = _readWav(File('${args[0]}/${name}v$v.wav'));
      layers[v] = _cut(stereo, seconds, fade: v == 8 ? 1.5 : 1.0);
    }
    // Kept at the level recorded, which packs smaller than turned up. One
    // gain for all the layers of a note, set by the normal one, so that the
    // soft one stays soft and the firm one firm: PianoSamples.gains.
    final gain = 0.14 / _rms(layers[8]!, _rate);
    final cents = _cents(layers[8]![0], _midi(name));
    stdout.writeln(
      '${_midi(name)}: ${cents.toStringAsFixed(1)} cents, '
      'gain ${gain.toStringAsFixed(3)}',
    );
    for (final MapEntry(key: v, value: channels) in layers.entries) {
      _writePair(out, '${_file(name)}v$v', channels, 1);
    }
  }
  for (var midi = _lowestRelease; midi <= _highestRelease; midi++) {
    final stereo = _readWav(File('${args[0]}/rel${midi - 20}.wav'));
    _writePair(out, 'rel$midi', _cut(stereo, 1.0, fade: 0.2), 1);
  }
}

String _file(String name) => name.replaceAll('#', 's');

int _midi(String name) {
  const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A'];
  final pitch = name.substring(0, name.length - 1);
  final octave = int.parse(name.substring(name.length - 1));
  final pc = pitch == 'A#' ? 10 : (pitch == 'B' ? 11 : names.indexOf(pitch));
  return (octave + 1) * 12 + pc;
}

/// Both channels of a 48 kHz 16- or 24-bit WAV file, from -1 to 1.
List<Float64List> _readWav(File file) {
  final bytes = file.readAsBytesSync();
  final view = ByteData.sublistView(bytes);
  var at = 12;
  var channels = 2, bits = 24;
  int? dataAt, dataLength;
  while (at + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(at, at + 4));
    final size = view.getUint32(at + 4, Endian.little);
    if (id == 'fmt ') {
      channels = view.getUint16(at + 10, Endian.little);
      final rate = view.getUint32(at + 12, Endian.little);
      bits = view.getUint16(at + 22, Endian.little);
      if (rate != _rate) throw StateError('${file.path}: $rate Hz');
      if (channels != 2) throw StateError('${file.path}: $channels channels');
    } else if (id == 'data') {
      dataAt = at + 8;
      dataLength = size;
      break;
    }
    at += 8 + size + (size.isOdd ? 1 : 0);
  }
  if (dataAt == null) throw StateError('${file.path}: no data');
  final width = bits ~/ 8;
  final frames = dataLength! ~/ (width * channels);
  final out = [Float64List(frames), Float64List(frames)];
  for (var i = 0; i < frames; i++) {
    for (var c = 0; c < 2; c++) {
      final p = dataAt + (i * channels + c) * width;
      out[c][i] = width == 3
          ? (bytes[p] | bytes[p + 1] << 8 | bytes[p + 2] << 16).toSigned(24) /
                8388608
          : view.getInt16(p, Endian.little) / 32768;
    }
  }
  return out;
}

/// From 3 ms before the attack (the first sample 50 dB under the peak),
/// [seconds] long at most, the last [fade] seconds faded out.
List<Float64List> _cut(
  List<Float64List> x,
  double seconds, {
  required double fade,
}) {
  final peak = _peak(x);
  var start = 0;
  final floor = peak * math.pow(10, -50 / 20);
  while (start < x[0].length &&
      x[0][start].abs() < floor &&
      x[1][start].abs() < floor) {
    start++;
  }
  start = math.max(0, start - (_rate * 0.003).round());
  final length = math.min(x[0].length - start, (_rate * seconds).round());
  final f = math.min(length, (_rate * fade).round());
  return [
    for (final c in x)
      Float64List.fromList([
        for (var i = 0; i < length; i++)
          c[start + i] *
              (i < length - f
                  ? 1
                  : 0.5 * (1 + math.cos(math.pi * (i - length + f) / f))),
      ]),
  ];
}

double _peak(List<Float64List> x) {
  var top = 0.0;
  for (final c in x) {
    for (final v in c) {
      top = math.max(top, v.abs());
    }
  }
  return top;
}

/// The loudness of the first [n] samples (the body of the note).
double _rms(List<Float64List> x, int n) {
  var e = 0.0;
  var count = 0;
  for (final c in x) {
    for (var i = 0; i < math.min(n, c.length); i++) {
      e += c[i] * c[i];
      count++;
    }
  }
  return math.sqrt(e / count);
}

/// How far, in cents, the recording of [midi] is from equal temperament at
/// A = 440: the mean of its first two partials, each found by the
/// strongest frequency within 60 cents of where it should be, over two
/// seconds of the held note.
double _cents(Float64List x, int midi) {
  final f0 = 440 * math.pow(2, (midi - 69) / 12);
  final from = (_rate * 0.3).round(), n = _rate * 2;
  final window = Float64List(n);
  for (var i = 0; i < n; i++) {
    window[i] = x[from + i] * (0.5 - 0.5 * math.cos(2 * math.pi * i / n));
  }
  double partial(double f) {
    double power(double cents) {
      final w = 2 * math.pi * f * math.pow(2, cents / 1200) / _rate;
      var re = 0.0, im = 0.0;
      for (var i = 0; i < n; i++) {
        re += window[i] * math.cos(w * i);
        im += window[i] * math.sin(w * i);
      }
      return re * re + im * im;
    }

    // Coarse, then fine around the best.
    var best = 0.0, bestPower = -1.0;
    for (var c = -60.0; c <= 60; c += 1) {
      final p = power(c);
      if (p > bestPower) (best, bestPower) = (c, p);
    }
    final centre = best;
    for (var c = centre - 1; c <= centre + 1; c += 0.05) {
      final p = power(c);
      if (p > bestPower) (best, bestPower) = (c, p);
    }
    return best;
  }

  return (partial(f0.toDouble()) + partial(2 * f0.toDouble())) / 2;
}

/// Writes the two channels as [name]L.wav and [name]R.wav: mono 16-bit,
/// at [gain]. No dither is added: the room noise of the recording, some
/// 70 dB down, is already far above the last bit and does its work, and
/// added noise would only make the files larger.
void _writePair(
  Directory out,
  String name,
  List<Float64List> channels,
  double gain,
) {
  for (var c = 0; c < 2; c++) {
    final x = channels[c];
    final data = x.length * 2;
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
    bytes.setUint32(24, _rate, Endian.little);
    bytes.setUint32(28, _rate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, data, Endian.little);
    for (var i = 0; i < x.length; i++) {
      final s = (x[i] * gain * 32767).round().clamp(-32768, 32767);
      bytes.setInt16(44 + i * 2, s, Endian.little);
    }
    File('${out.path}/$name${c == 0 ? 'L' : 'R'}.wav')
        .writeAsBytesSync(bytes.buffer.asUint8List());
  }
}
