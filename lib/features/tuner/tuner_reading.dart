import '../../audio/pitch.dart';

/// What the tuner shows for one detected frequency.
class TunerReading {
  const TunerReading._(this.frequency, this.played, this.target, this.cents);

  /// Compares [frequency] with the nearest note.
  factory TunerReading.of(double frequency, {double a4 = 440}) {
    final played = Note.nearest(frequency, a4: a4);
    return TunerReading._(
      frequency,
      played,
      played,
      played.centsOf(frequency, a4: a4),
    );
  }

  /// Within this many cents a note counts as in tune.
  static const inTuneCents = 5.0;

  final double frequency;

  /// The note actually heard.
  final Note played;

  /// The note to tune to: the note heard, as the tuner is chromatic.
  final Note target;

  /// Distance from [target]: negative when flat, positive when sharp.
  final double cents;

  bool get inTune => cents.abs() <= inTuneCents;
}
