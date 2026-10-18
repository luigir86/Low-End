/// Softer clicks between the beats, to place the notes inside them: none,
/// two (eighths), three (triplets) or four (sixteenths) to a beat.
enum Subdivision {
  none(1),
  eighths(2),
  triplets(3),
  sixteenths(4);

  const Subdivision(this.parts);

  /// How many equal parts a beat is split into; 1 when it is not.
  final int parts;
}
