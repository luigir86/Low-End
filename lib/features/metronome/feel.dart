/// How the beat is felt, the way a drummer plays it.
enum MetronomeFeel {
  /// One stroke on each beat.
  straight,

  /// A jazz ride: the beat, and the skip note after beats 2 and 4, a
  /// triplet in three (long, short), with the hi-hat on 2 and 4.
  swing,

  /// Every beat in two uneven halves, long and short, as in a blues
  /// shuffle.
  shuffle,
}
