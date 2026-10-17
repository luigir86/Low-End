import '../../audio/pitch.dart';

/// What the tuner compares a note with: any note of the scale (chromatic),
/// or the open strings of an instrument, the nearest of them being the one
/// to tune.
enum TunerTuning {
  chromatic(<Note>[]),

  /// G3 D4 A4 E5.
  violin(<Note>[Note(7, 3), Note(2, 4), Note(9, 4), Note(4, 5)]),

  /// E1 A1 D2 G2: the double bass and the electric bass.
  bass(<Note>[Note(4, 1), Note(9, 1), Note(2, 2), Note(7, 2)]),

  /// B0 E1 A1 D2 G2: a bass with a low B string (30.9 Hz).
  bassFive(<Note>[Note(11, 0), Note(4, 1), Note(9, 1), Note(2, 2), Note(7, 2)]);

  const TunerTuning(this.strings);

  /// The open strings, lowest first; empty when chromatic.
  final List<Note> strings;

  bool get isChromatic => strings.isEmpty;

  /// The string closest to [frequency], by distance in cents, or null when
  /// chromatic.
  Note? nearestString(double frequency, {double a4 = 440}) {
    Note? best;
    var bestOff = double.infinity;
    for (final string in strings) {
      final off = string.centsOf(frequency, a4: a4).abs();
      if (off < bestOff) {
        bestOff = off;
        best = string;
      }
    }
    return best;
  }
}
