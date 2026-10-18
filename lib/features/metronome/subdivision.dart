/// Softer clicks between the beats, to place the notes inside them: none
/// (the quarter note alone), two (eighths), three (triplets) or four
/// (sixteenths) to a beat, or the same pairs swung, as MuseScore plays
/// "Swing": written straight, played long-short, the second note of each pair
/// at 60% of it (3:2).
enum Subdivision {
  quarters([]),
  eighths([0.5]),
  swungEighths([swing]),
  triplets([1 / 3, 2 / 3]),
  sixteenths([0.25, 0.5, 0.75]),
  swungSixteenths([swing / 2, 0.5, 0.5 + swing / 2]);

  const Subdivision(this.inner);

  /// Where the second note of a swung pair falls, in the pair.
  static const swing = 0.6;

  /// Where the clicks between the beats fall, as a fraction of the beat
  /// (the beat's own click is at 0).
  final List<double> inner;

  /// How many notes fill a beat; 1 when it is not split.
  int get notes => inner.length + 1;

  /// Whether the pairs are played long-short.
  bool get swung => this == swungEighths || this == swungSixteenths;

  /// The name an assistant uses: the same as the enum's, with underscores.
  String get id => switch (this) {
    quarters => 'quarters',
    eighths => 'eighths',
    swungEighths => 'swing_eighths',
    triplets => 'triplets',
    sixteenths => 'sixteenths',
    swungSixteenths => 'swing_sixteenths',
  };
}
