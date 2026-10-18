import 'dart:math' as math;

/// The range of the reference A4, in whole hertz: from the baroque 415 to
/// 445, above what any orchestra tunes to.
const minReferencePitch = 415.0;
const maxReferencePitch = 445.0;

/// Whether [hz] is a whole number of hertz within the range of the reference A.
bool isReferencePitch(double hz) =>
    hz == hz.roundToDouble() &&
    hz >= minReferencePitch &&
    hz <= maxReferencePitch;

/// Every reference pitch in ascending order: 415, 416… 445 Hz.
final referencePitches = [
  for (var hz = minReferencePitch; hz <= maxReferencePitch; hz++) hz,
];

/// How note names are written.
enum NoteNames {
  /// C, D, E… with scientific octave numbers: A4 = 440 Hz.
  letters,

  /// Do, Re, Mi… with the octave numbers used in Italy and France, one lower
  /// than the scientific ones: La3 = 440 Hz.
  solfege,
}

/// How octaves are numbered, independently of how notes are named.
enum OctaveNumbering {
  /// Scientific: middle C is C4, A4 = 440 Hz, the double bass low E is E1
  /// (41.2 Hz). The default.
  scientific,

  /// As often taught in Italy and France: one lower, so La3 = 440 Hz and the
  /// low E is Mi0.
  italian,
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

  /// The octave number as written with [numbering]. Without it, the number
  /// follows [names] as it used to: the Italian numbering for solfège. The
  /// app always passes the player's choice.
  int octaveIn(NoteNames names, {OctaveNumbering? numbering}) {
    final italian = numbering != null
        ? numbering == OctaveNumbering.italian
        : names == NoteNames.solfege;
    return italian ? octave - 1 : octave;
  }

  /// The note name with its octave number, such as "A4", or "La3" with the
  /// Italian numbering (the same note, 440 Hz).
  String label(NoteNames names, {OctaveNumbering? numbering}) =>
      '${name(names)}${octaveIn(names, numbering: numbering)}';

  @override
  bool operator ==(Object other) =>
      other is Note && other.pitchClass == pitchClass && other.octave == octave;

  @override
  int get hashCode => Object.hash(pitchClass, octave);
}

/// The key of a transposing instrument: the note it reads as C sounds
/// [key], so its written notes are [semitones] above the sounding ones.
/// The common ones: clarinet, trumpet and soprano and tenor sax in B♭; alto
/// and baritone sax in E♭; horn in F. The octave is the one of a B♭
/// trumpet, an alto sax and a horn; a tenor or baritone sax reads one higher.
enum Transposition {
  /// Concert pitch: notes are named as they sound.
  c(0, 0),
  bFlat(10, 2),
  eFlat(3, 9),
  f(5, 7);

  const Transposition(this.key, this.semitones);

  /// The pitch class the instrument's written C sounds.
  final int key;

  /// How far above the sounding note the written one is.
  final int semitones;

  /// The note an instrument in this key reads for the sounding [note].
  Note written(Note note) {
    final midi = note.midi + semitones;
    return Note(midi % 12, midi ~/ 12 - 1);
  }
}
