import '../../audio/pitch.dart';
import 'tuner_tuning.dart';

/// What the tuner shows for one detected frequency.
class TunerReading {
  const TunerReading._(
    this.frequency,
    this.played,
    this.target,
    this.cents,
    this.tolerance,
    this.onStrings,
    this.stringNumber,
  );

  /// True when [target] is an open string chosen from an instrument's
  /// tuning, rather than the note heard.
  final bool onStrings;

  /// The number of [target] on the instrument, 1 being the thinnest string.
  final int? stringNumber;

  /// Compares [frequency] with the nearest note, or with the nearest open
  /// string of [tuning] when it has any; it counts as in tune within
  /// [tolerance] cents.
  factory TunerReading.of(
    double frequency, {
    double a4 = 440,
    double tolerance = inTuneCents,
    TunerTuning tuning = TunerTuning.chromatic,
  }) {
    final played = Note.nearest(frequency, a4: a4);
    final target = tuning.nearestString(frequency, a4: a4) ?? played;
    return TunerReading._(
      frequency,
      played,
      target,
      target.centsOf(frequency, a4: a4),
      tolerance,
      !tuning.isChromatic,
      tuning.numberOf(target),
    );
  }

  /// Within this many cents a note counts as in tune, unless the player
  /// chose another width in the settings.
  static const inTuneCents = 5.0;

  final double frequency;

  /// The note actually heard.
  final Note played;

  /// The note to tune to: the note heard, as the tuner is chromatic.
  final Note target;

  /// Distance from [target]: negative when flat, positive when sharp.
  final double cents;

  /// How many cents either side of [target] still count as in tune.
  final double tolerance;

  bool get inTune => cents.abs() <= tolerance;
}
