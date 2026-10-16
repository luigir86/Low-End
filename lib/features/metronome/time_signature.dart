/// A time signature as the metronome plays it: how many pulses in a bar and
/// how they group.
///
/// The tempo counts the pulses (the segments of the ring): quarter notes in
/// x/4, eighth notes in x/8. 3/4 and 6/8 hold the same number of eighths but
/// feel different, so they differ in the grouping: 3/4 is three equal beats,
/// 6/8 is two groups of three, with a stronger click on the first pulse of
/// each group.
class TimeSignature {
  const TimeSignature(this.numerator, this.denominator, this.groups);

  final int numerator;
  final int denominator;

  /// Pulses in each group, adding up to [numerator]; one group when the bar
  /// is felt as plain beats.
  final List<int> groups;

  static const twoFour = TimeSignature(2, 4, [2]);
  static const threeFour = TimeSignature(3, 4, [3]);
  static const fourFour = TimeSignature(4, 4, [4]);
  static const fiveFour = TimeSignature(5, 4, [3, 2]);
  static const sixEight = TimeSignature(6, 8, [3, 3]);
  static const sevenEight = TimeSignature(7, 8, [2, 2, 3]);
  static const nineEight = TimeSignature(9, 8, [3, 3, 3]);
  static const twelveEight = TimeSignature(12, 8, [3, 3, 3, 3]);

  static const all = [
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
