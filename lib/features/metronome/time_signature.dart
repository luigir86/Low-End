/// The note value a tempo counts, as written above a score: "♩ = 120".
enum BeatUnit {
  quarter('♩'),
  dottedQuarter('♩.'),
  eighth('♪');

  const BeatUnit(this.symbol);

  final String symbol;
}

/// A time signature as the metronome plays it: how many pulses in a bar and
/// how they group.
///
/// The pulses are the segments of the ring: quarter notes in x/4, eighth
/// notes in x/8. The tempo counts the beat a player feels: the quarter note
/// in x/4, the dotted quarter in the compound bars (6/8, 9/8, 12/8: three
/// pulses to a beat), the eighth in 7/8, whose groups are uneven. 3/4 and
/// 6/8 hold the same number of eighths but feel different, so they differ in
/// the grouping: 3/4 is three equal beats, 6/8 is two groups of three, with
/// a stronger click on the first pulse of each group. 1/1 is a bar of one
/// beat, to keep a tempo without counting: every click is the "one".
class TimeSignature {
  const TimeSignature(this.numerator, this.denominator, this.groups);

  final int numerator;
  final int denominator;

  /// Pulses in each group, adding up to [numerator]; one group when the bar
  /// is felt as plain beats.
  final List<int> groups;

  static const oneOne = TimeSignature(1, 1, [1]);
  static const twoFour = TimeSignature(2, 4, [2]);
  static const threeFour = TimeSignature(3, 4, [3]);
  static const fourFour = TimeSignature(4, 4, [4]);
  static const fiveFour = TimeSignature(5, 4, [3, 2]);
  static const sixEight = TimeSignature(6, 8, [3, 3]);
  static const sevenEight = TimeSignature(7, 8, [2, 2, 3]);
  static const nineEight = TimeSignature(9, 8, [3, 3, 3]);
  static const twelveEight = TimeSignature(12, 8, [3, 3, 3, 3]);

  static const all = [
    oneOne,
    twoFour,
    threeFour,
    fourFour,
    fiveFour,
    sixEight,
    sevenEight,
    nineEight,
    twelveEight,
  ];

  int get beats => numerator;

  /// True when the bar is split into groups with their own strong pulse.
  bool get grouped => groups.length > 1;

  /// True for the compound bars, 6/8, 9/8 and 12/8: eighths in groups of
  /// three, each group one beat (a dotted quarter).
  bool get compound =>
      denominator == 8 && grouped && groups.every((g) => g == 3);

  /// Pulses (segments of the ring) in one beat of the tempo.
  int get pulsesPerBeat => compound ? 3 : 1;

  /// The note value the tempo counts.
  BeatUnit get beatUnit => compound
      ? BeatUnit.dottedQuarter
      : (denominator == 8 ? BeatUnit.eighth : BeatUnit.quarter);

  /// How strong pulse [beat] is: 0 for the "one", 1 for the first pulse of
  /// another group, 2 for the others.
  int accent(int beat) {
    if (beat == 0) return 0;
    var start = 0;
    for (final g in groups) {
      if (beat == start) return grouped ? 1 : 2;
      start += g;
    }
    return 2;
  }

  /// True when the click can fall on 2 and 4 only, the beats a jazz
  /// drummer's hi-hat plays: in 2/4 and 4/4.
  bool get hasBackbeat => denominator == 4 && !grouped && numerator.isEven;

  /// Written as "6/8".
  String get label => '$numerator/$denominator';

  /// How the bar is felt, such as "3 + 3".
  String get feel => groups.length == 1 ? '$numerator' : groups.join(' + ');

  @override
  bool operator ==(Object other) =>
      other is TimeSignature &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);
}
