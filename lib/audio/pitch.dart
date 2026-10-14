import 'dart:math' as math;

/// Reference pitches for A4 that orchestras commonly tune to.
const referencePitches = [440.0, 441.0, 442.0, 443.0];

/// Names of the 12 pitch classes, starting from C, in the spelling a bassist
/// usually reads (flats for E♭, A♭ and B♭).
const _englishNames = [
  'C', 'C♯', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B', //
];
const _italianNames = [
  'Do', 'Do♯', 'Re', 'Mi♭', 'Mi', 'Fa', 'Fa♯', 'Sol', 'La♭', 'La', 'Si♭',
  'Si', //
];

/// A note in scientific pitch notation: [pitchClass] 0 = C … 11 = B, and
/// [octave] where E1 is the double bass low E string (about 41.2 Hz).
class Note {
  const Note(this.pitchClass, this.octave)
    : assert(pitchClass >= 0 && pitchClass < 12);

  final int pitchClass;
  final int octave;

  /// MIDI number: A4 = 69.
  int get midi => (octave + 1) * 12 + pitchClass;

  /// Equal-tempered frequency in Hz, given the frequency of A4.
  double frequency({double a4 = 440}) =>
      a4 * math.pow(2, (midi - 69) / 12).toDouble();

  /// The note name without octave, for the given language code.
  String name(String languageCode) =>
      (languageCode == 'it' ? _italianNames : _englishNames)[pitchClass];

  /// The note name with its octave number, such as "A2" or "La2".
  String label(String languageCode) => '${name(languageCode)}$octave';

  @override
  bool operator ==(Object other) =>
      other is Note && other.pitchClass == pitchClass && other.octave == octave;

  @override
  int get hashCode => Object.hash(pitchClass, octave);
}
