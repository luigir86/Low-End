import 'dart:typed_data';

import 'package:flutter/services.dart';

/// The recorded drum strokes of the metronome: a few short mono 44.1 kHz
/// recordings (the ride, its bell, a soft ride for the skip note, the bass
/// drum, the snare and the hi-hat closing with the foot), from the
/// Versilian Community Sample Library (CC0, see the About page and
/// `assets/drums/README.md`).
class DrumKit {
  const DrumKit({
    required this.ride,
    required this.bell,
    required this.ghost,
    required this.kick,
    required this.snare,
    required this.chick,
  });

  /// Mono samples from -1 to 1, each starting at its attack.
  final Float64List ride, bell, ghost, kick, snare, chick;

  static const sampleRate = 44100;

  /// The strokes, by the name of their file in `assets/drums`.
  static const names = ['ride', 'bell', 'ghost', 'kick', 'snare', 'chick'];

  static String assetOf(String name) => 'assets/drums/$name.wav';

  /// Reads the recordings from the app's assets.
  static Future<DrumKit> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final files = <String, Uint8List>{};
    for (final name in names) {
      final data = await b.load(assetOf(name));
      files[name] = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
    }
    return DrumKit.fromWavs(files);
  }

  /// A kit from the WAV files, by name (see [names]).
  factory DrumKit.fromWavs(Map<String, Uint8List> files) {
    Float64List sound(String name) => decodeWav(files[name]!);
    return DrumKit(
      ride: sound('ride'),
      bell: sound('bell'),
      ghost: sound('ghost'),
      kick: sound('kick'),
      snare: sound('snare'),
      chick: sound('chick'),
    );
  }

  /// Mono 16-bit samples of a WAV file with a 44-byte header, from -1 to 1.
  static Float64List decodeWav(Uint8List wav) {
    final view = ByteData.sublistView(wav);
    final n = (wav.length - 44) ~/ 2;
    return Float64List.fromList([
      for (var i = 0; i < n; i++)
        view.getInt16(44 + i * 2, Endian.little) / 32768,
    ]);
  }
}
