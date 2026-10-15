import '../../audio/pitch.dart';

enum Instrument { doubleBass, electricBass }

/// The open strings of an instrument, from lowest to highest, at their
/// sounding pitch.
class Tuning {
  const Tuning(this.id, this.instrument, this.strings);

  /// Stable name, also used to look up the translated label.
  final String id;
  final Instrument instrument;
  final List<Note> strings;
}

const _b0 = Note(11, 0);
const _c1 = Note(0, 1);
const _d1 = Note(2, 1);
const _e1 = Note(4, 1);
const _fSharp1 = Note(6, 1);
const _a1 = Note(9, 1);
const _b1 = Note(11, 1);
const _d2 = Note(2, 2);
const _e2 = Note(4, 2);
const _g2 = Note(7, 2);
const _a2 = Note(9, 2);
const _c3 = Note(0, 3);

const tunings = [
  Tuning('orchestral', Instrument.doubleBass, [_e1, _a1, _d2, _g2]),
  // Solo strings sound a whole tone higher than orchestral ones.
  Tuning('solo', Instrument.doubleBass, [_fSharp1, _b1, _e2, _a2]),
  Tuning('cExtension', Instrument.doubleBass, [_c1, _a1, _d2, _g2]),
  Tuning('fiveLowB', Instrument.doubleBass, [_b0, _e1, _a1, _d2, _g2]),
  Tuning('fiveHighC', Instrument.doubleBass, [_e1, _a1, _d2, _g2, _c3]),
  Tuning('fourStrings', Instrument.electricBass, [_e1, _a1, _d2, _g2]),
  Tuning('fiveStrings', Instrument.electricBass, [_b0, _e1, _a1, _d2, _g2]),
  Tuning('sixStrings', Instrument.electricBass, [
    _b0, _e1, _a1, _d2, _g2, _c3, //
  ]),
  Tuning('dropD', Instrument.electricBass, [_d1, _a1, _d2, _g2]),
];

/// What the tuner shows for one detected frequency.
class TunerReading {
  const TunerReading._(this.frequency, this.played, this.target, this.cents);

  /// Compares [frequency] with the nearest note, or with the nearest open
  /// string when a [tuning] is chosen.
  factory TunerReading.of(double frequency, {Tuning? tuning, double a4 = 440}) {
    final played = Note.nearest(frequency, a4: a4);
    double distance(Note n) => n.centsOf(frequency, a4: a4).abs();
    final target = tuning == null
        ? played
        : tuning.strings.reduce((a, b) => distance(a) <= distance(b) ? a : b);
    return TunerReading._(
      frequency,
      played,
      target,
      target.centsOf(frequency, a4: a4),
    );
  }

  /// Within this many cents a string counts as in tune.
  static const inTuneCents = 5.0;

  final double frequency;

  /// The note actually heard.
  final Note played;

  /// The note to tune to: [played] itself, or the nearest open string.
  final Note target;

  /// Distance from [target]: negative when flat, positive when sharp.
  final double cents;

  bool get inTune => cents.abs() <= inTuneCents;
}
