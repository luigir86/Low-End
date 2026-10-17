import '../../audio/pitch.dart';

/// What the tuner compares a note with: any note of the scale (chromatic),
/// or the open strings of an instrument, the nearest of them being the one
/// to tune.
///
/// Strings are listed lowest note first. [numbers] gives the number of each
/// string in the same order: string I is the thinnest, the highest one, as
/// bowed-string players and guitarists count them (a ukulele's re-entrant
/// G is its fourth string, though not the lowest note).
enum TunerTuning {
  chromatic(<Note>[], <int>[]),

  /// E2 A2 D3 G3 B3 E4.
  guitar(
    <Note>[
      Note(4, 2),
      Note(9, 2),
      Note(2, 3),
      Note(7, 3),
      Note(11, 3),
      Note(4, 4),
    ],
    <int>[6, 5, 4, 3, 2, 1],
  ),

  /// E1 A1 D2 G2: the double bass and the electric bass.
  bass(
    <Note>[Note(4, 1), Note(9, 1), Note(2, 2), Note(7, 2)],
    <int>[4, 3, 2, 1],
  ),

  /// B0 E1 A1 D2 G2: a bass with a low B string (30.9 Hz).
  bassFive(
    <Note>[Note(11, 0), Note(4, 1), Note(9, 1), Note(2, 2), Note(7, 2)],
    <int>[5, 4, 3, 2, 1],
  ),

  /// C4 E4 G4 A4, with the G above the C: the usual re-entrant tuning.
  ukulele(
    <Note>[Note(0, 4), Note(4, 4), Note(7, 4), Note(9, 4)],
    <int>[3, 2, 4, 1],
  ),

  /// G3 D4 A4 E5.
  violin(
    <Note>[Note(7, 3), Note(2, 4), Note(9, 4), Note(4, 5)],
    <int>[4, 3, 2, 1],
  ),

  /// C3 G3 D4 A4.
  viola(
    <Note>[Note(0, 3), Note(7, 3), Note(2, 4), Note(9, 4)],
    <int>[4, 3, 2, 1],
  ),

  /// C2 G2 D3 A3.
  cello(
    <Note>[Note(0, 2), Note(7, 2), Note(2, 3), Note(9, 3)],
    <int>[4, 3, 2, 1],
  );

  const TunerTuning(this.strings, this.numbers);

  /// The open strings, lowest note first; empty when chromatic.
  final List<Note> strings;

  /// The number of each string of [strings], 1 being the thinnest.
  final List<int> numbers;

  bool get isChromatic => strings.isEmpty;

  /// The instruments, in the order of the menu.
  static const instruments = <TunerTuning>[
    guitar,
    bass,
    bassFive,
    ukulele,
    violin,
    viola,
    cello,
  ];

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

  /// The number of [string] (1 is the thinnest), or null when it is not a
  /// string of this instrument.
  int? numberOf(Note string) {
    final i = strings.indexWhere((s) => s.midi == string.midi);
    return i < 0 ? null : numbers[i];
  }
}

/// A string number as a Roman numeral, as strings are written in music.
String romanNumeral(int n) =>
    const ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII'][n.clamp(0, 7)];
