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

  test('names follow the language', () {
    expect(const Note(10, 2).label('en'), 'B♭2');
    expect(const Note(10, 2).label('it'), 'Si♭2');
    expect(const Note(0, 3).label('it'), 'Do3');
  });
}
