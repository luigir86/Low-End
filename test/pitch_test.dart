import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/pitch.dart';

void main() {
  test('A4 matches the reference pitch', () {
    expect(const Note(9, 4).frequency(), 440);
    expect(const Note(9, 4).frequency(a4: 442), 442);
  });

  test('double bass open strings have the expected frequencies', () {
    expect(const Note(4, 1).frequency(), closeTo(41.20, 0.01)); // E1
    expect(const Note(9, 1).frequency(), closeTo(55.00, 0.01)); // A1
    expect(const Note(2, 2).frequency(), closeTo(73.42, 0.01)); // D2
    expect(const Note(7, 2).frequency(), closeTo(98.00, 0.01)); // G2
    expect(const Note(11, 0).frequency(), closeTo(30.87, 0.01)); // low B
  });

  test('names follow the chosen style, with Italian octave numbers', () {
    expect(const Note(10, 2).label(NoteNames.letters), 'B♭2');
    expect(const Note(10, 2).label(NoteNames.solfege), 'Si♭1');
    // Middle C and the tuning A: C4 and A4, or Do3 and La3.
    expect(const Note(0, 4).label(NoteNames.solfege), 'Do3');
    expect(const Note(9, 4).label(NoteNames.letters), 'A4');
    expect(const Note(9, 4).label(NoteNames.solfege), 'La3');
  });

  test('a note is spelled on the letter its key asks for', () {
    // D♯ (on D) rather than E♭, G♯ rather than A♭, as in C♯ minor.
    expect(spell(3, 1, NoteNames.letters), 'D♯');
    expect(spell(8, 4, NoteNames.solfege), 'Sol♯');
    expect(spell(6, 4, NoteNames.letters), 'G♭');
    expect(spell(11, 0, NoteNames.letters), 'C♭');
    expect(spell(0, 0, NoteNames.solfege), 'Do');
    // A double sharp is not written: the usual name instead.
    expect(spell(2, 0, NoteNames.letters), 'D');
    // The usual letters give the usual names.
    for (var pc = 0; pc < 12; pc++) {
      for (final names in NoteNames.values) {
        expect(spell(pc, letterOf(pc), names), Note(pc, 4).name(names));
      }
    }
    expect(letterOf(1, flat: true), 1);
    expect(const Note(1, 4).name(NoteNames.letters, flat: true), 'D♭');
    expect(const Note(6, 4).name(NoteNames.solfege, flat: true), 'Sol♭');
  });
}
