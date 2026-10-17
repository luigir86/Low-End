/// How the beat is felt, the way a drummer plays it.
enum MetronomeFeel {
  /// One stroke on each beat.
  straight,

  /// A jazz ride: the beat, and the skip note after beats 2 and 4, a
  /// triplet in three (long, short), with the hi-hat on 2 and 4.
  swing,

  /// Every beat in two uneven halves, long and short, as in a blues
  /// shuffle.
  shuffle;

  /// Whether a skip note falls two thirds of the way through [beat] (0 for
  /// the first) of a bar of [beats]: after every beat in the shuffle, after
  /// 2 and 4 in the swing (the only beat of a bar of one).
  bool skipsAfter(int beat, int beats) => switch (this) {
    straight => false,
    swing => beat.isOdd || beats == 1,
    shuffle => true,
  };

  /// Where the skip note falls in a beat of [beat] samples: the second
  /// note of a triplet.
  static int skipAt(int beat) => beat * 2 ~/ 3;
}
