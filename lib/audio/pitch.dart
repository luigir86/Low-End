import 'dart:math' as math;

/// Reference pitches for A4 offered in the settings, in ascending order: the
/// baroque 415, 430 and 432 Hz, then 438 to 445 Hz around the 440 to 443 that
/// most orchestras tune to.
const referencePitches = [
  415.0, 430.0, 432.0, 438.0, 439.0, 440.0, 441.0, 442.0, 443.0, 444.0, //
  445.0,
];

/// How note names are written.
enum NoteNames {
  /// C, D, E… with scientific octave numbers: A4 = 440 Hz.
  letters,

  /// Do, Re, Mi… with the octave numbers used in Italy and France, one lower
  /// than the scientific ones: La3 = 440 Hz.
  solfege,
}

/// Names of the 12 pitch classes, starting from C, in the spelling a bassist
/// usually reads (flats for E♭, A♭ and B♭).
const _englishNames = [
  'C', 'C♯', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B', //
];
const _italianNames = [
  'Do', 'Do♯', 'Re', 'Mi♭', 'Mi', 'Fa', 'Fa♯', 'Sol', 'La♭', 'La', 'Si♭',
  'Si', //
];

/// The seven letters, C to B, their pitch classes and their names.
const _naturals = [0, 2, 4, 5, 7, 9, 11];
const _englishLetters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
const _italianLetters = ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'];

/// The letter of each pitch class (0 = C … 6 = B) as the names above write
/// it: C♯ on C, E♭ on E.
const _usualLetters = [0, 0, 1, 2, 2, 3, 3, 4, 5, 5, 6, 6];

/// The letter (0 = C … 6 = B) [pitchClass] is written with: the usual one,
/// or for a black key with [flat], the letter above (D♭ rather than C♯).
int letterOf(int pitchClass, {bool flat = false}) {
  final natural = _naturals.indexOf(pitchClass);
  if (natural >= 0) return natural;
  return flat
      ? _naturals.indexOf((pitchClass + 1) % 12)
      : _usualLetters[pitchClass];
}

/// [pitchClass] written on [letter] (0 = C … 6 = B) with a sharp or a flat
/// as needed, such as D♯ or Re♭: how a note is spelled in a key. Where that
/// would take a double sharp or flat, the usual name instead.
String spell(int pitchClass, int letter, NoteNames names) {
  final base = (names == NoteNames.solfege
      ? _italianLetters
      : _englishLetters)[letter];
  return switch ((pitchClass - _naturals[letter] + 18) % 12 - 6) {
    0 => base,
    1 => '$base♯',
    -1 => '$base♭',
    _ => Note(pitchClass, 4).name(names),
  };
}

/// A note in scientific pitch notation: [pitchClass] 0 = C … 11 = B, and
/// [octave] where E1 is the double bass low E string (about 41.2 Hz).
class Note {
  const Note(this.pitchClass, this.octave)
    : assert(pitchClass >= 0 && pitchClass < 12);

  /// The equal-tempered note closest to [frequency] in Hz.
  factory Note.nearest(double frequency, {double a4 = 440}) {
    final midi = (69 + 12 * math.log(frequency / a4) / math.ln2).round();
    return Note(midi % 12, midi ~/ 12 - 1);
  }

  final int pitchClass;
  final int octave;

  /// MIDI number: A4 = 69.
  int get midi => (octave + 1) * 12 + pitchClass;

  /// Equal-tempered frequency in Hz, given the frequency of A4.
  double frequency({double a4 = 440}) =>
      a4 * math.pow(2, (midi - 69) / 12).toDouble();

  /// How far [frequency] is from this note, in cents (hundredths of a
  /// semitone): negative when flat, positive when sharp.
  double centsOf(double frequency, {double a4 = 440}) =>
      1200 * math.log(frequency / this.frequency(a4: a4)) / math.ln2;

  /// The note name without octave; with [flat], a black key is written
  /// with a flat (D♭, G♭).
  String name(NoteNames names, {bool flat = false}) => flat
      ? spell(pitchClass, letterOf(pitchClass, flat: true), names)
      : (names == NoteNames.solfege
            ? _italianNames
            : _englishNames)[pitchClass];

  /// The octave number as written with [names].
  int octaveIn(NoteNames names) =>
      names == NoteNames.solfege ? octave - 1 : octave;

  /// The note name with its octave number, such as "A4" or "La3" (the same
  /// note, 440 Hz).
  String label(NoteNames names) => '${name(names)}${octaveIn(names)}';

  @override
  bool operator ==(Object other) =>
      other is Note && other.pitchClass == pitchClass && other.octave == octave;

  @override
  int get hashCode => Object.hash(pitchClass, octave);
}
