/// How the beat is felt, the way a drummer plays it.
enum MetronomeFeel {
  /// One click on each beat.
  straight,

  /// The beat, and a soft skip note after beats 2 and 4, a triplet in three
  /// (long, short), as a jazz ride.
  swing;

  /// Whether a skip note falls two thirds of the way through [beat] (0 for
  /// the first) of a bar of [beats]: after 2 and 4 in the swing (the only
  /// beat of a bar of one), never in the straight feel.
  bool skipsAfter(int beat, int beats) => switch (this) {
    straight => false,
    swing => beat.isOdd || beats == 1,
  };

  /// Where the skip note falls in a beat of [beat] samples: the second
  /// note of a triplet.
  static int skipAt(int beat) => beat * 2 ~/ 3;
}
