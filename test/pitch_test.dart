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

  test('the reference pitches are every whole hertz from 415 to 445', () {
    expect(referencePitches, hasLength(31));
    expect(referencePitches.first, 415);
    expect(referencePitches.last, 445);
    expect(referencePitches, containsAll([430.0, 432.0, 437.0, 440.0]));
    expect(referencePitches.every(isReferencePitch), isTrue);
    for (final hz in [414.0, 446.0, 440.5, double.nan, double.infinity]) {
      expect(isReferencePitch(hz), isFalse, reason: '$hz');
    }
  });
}
