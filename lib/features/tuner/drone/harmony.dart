/// Chords and progressions for the drone, in pure (just) intervals so the
/// notes do not beat against each other, which is what you want when
/// checking intonation.
library;

/// The kind of a chord, with its triad and, when sevenths are on, the
/// seventh added on top.
enum ChordQuality {
  /// Major triad; with the seventh, maj7 (major seventh, 15/8).
  major([1, 5 / 4, 3 / 2], [4, 7], 15 / 8, 11),

  /// Minor triad; with the seventh, m7 (minor seventh, 9/5).
  minor([1, 6 / 5, 3 / 2], [3, 7], 9 / 5, 10),

  /// Dominant seventh, 7: always played with its seventh, which makes it a
  /// dominant (see DroneController). The seventh is 16/9
  /// (996 cents), the pure ratio closest to the minor seventh a bassist
  /// plays: the harmonic seventh, 7/4, would sound 31 cents flat of it.
  dominant([1, 5 / 4, 3 / 2], [4, 7], 16 / 9, 10),

  /// Diminished triad; with the seventh, half-diminished (m7♭5).
  halfDiminished([1, 6 / 5, 64 / 45], [3, 6], 16 / 9, 10);

  const ChordQuality(
    this._triad,
    this._triadSemitones,
    this._seventh,
    this._seventhSemitones,
  );

  final List<double> _triad;
  final List<int> _triadSemitones;
  final double _seventh;
  final int _seventhSemitones;

  /// Ratios to the root, the root first.
  List<double> ratios({required bool seventh}) =>
      seventh ? [..._triad, _seventh] : _triad;

  /// The notes above the root, in semitones.
  List<int> semitones({required bool seventh}) =>
      seventh ? [..._triadSemitones, _seventhSemitones] : _triadSemitones;
}

/// One chord of a progression: its root, in semitones above the key, its
/// quality and its Roman numeral.
class ProgressionStep {
  const ProgressionStep(this.offset, this.quality, this.numeral);

  final int offset;
  final ChordQuality quality;
  final String numeral;

  /// Steps up the scale from the key, 0 for I, 4 for V: which letter the
  /// root is written with.
  int get degree => const [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
  ].indexOf(numeral.toUpperCase());
}

/// Standard progressions, one chord per bar, played over and over in the
/// key of the note touched.
enum Progression {
  /// Major II–V–I: in C, Dm G7 C (Dm7 G7 Cmaj7 with sevenths).
  twoFiveOne([
    ProgressionStep(2, ChordQuality.minor, 'II'),
    ProgressionStep(7, ChordQuality.dominant, 'V'),
    ProgressionStep(0, ChordQuality.major, 'I'),
  ]),

  /// Minor II–V–I: in C, D° G7 Cm (Dm7♭5 G7 Cm7 with sevenths).
  minorTwoFiveOne([
    ProgressionStep(2, ChordQuality.halfDiminished, 'II'),
    ProgressionStep(7, ChordQuality.dominant, 'V'),
    ProgressionStep(0, ChordQuality.minor, 'I'),
  ]),

  /// I–IV–V: in C, C F G7.
  oneFourFive([
    ProgressionStep(0, ChordQuality.major, 'I'),
    ProgressionStep(5, ChordQuality.major, 'IV'),
    ProgressionStep(7, ChordQuality.dominant, 'V'),
  ]),

  /// I–VI–IV–V: in C, C Am F G7.
  oneSixFourFive([
    ProgressionStep(0, ChordQuality.major, 'I'),
    ProgressionStep(9, ChordQuality.minor, 'VI'),
    ProgressionStep(5, ChordQuality.major, 'IV'),
    ProgressionStep(7, ChordQuality.dominant, 'V'),
  ]),

  /// Twelve-bar blues: I I I I, IV IV I I, V IV I V, all dominant sevenths.
  blues([
    ProgressionStep(0, ChordQuality.dominant, 'I'),
    ProgressionStep(0, ChordQuality.dominant, 'I'),
    ProgressionStep(0, ChordQuality.dominant, 'I'),
    ProgressionStep(0, ChordQuality.dominant, 'I'),
    ProgressionStep(5, ChordQuality.dominant, 'IV'),
    ProgressionStep(5, ChordQuality.dominant, 'IV'),
    ProgressionStep(0, ChordQuality.dominant, 'I'),
    ProgressionStep(0, ChordQuality.dominant, 'I'),
    ProgressionStep(7, ChordQuality.dominant, 'V'),
    ProgressionStep(5, ChordQuality.dominant, 'IV'),
    ProgressionStep(0, ChordQuality.dominant, 'I'),
    ProgressionStep(7, ChordQuality.dominant, 'V'),
  ]);

  const Progression(this.steps);

  final List<ProgressionStep> steps;
}

/// A well-known song to practise on: its key (as a pitch class), progression
/// and a comfortable tempo, set in one tap. The names are the songs' own and
/// are not translated.
class ExampleSong {
  const ExampleSong(this.title, this.pitchClass, this.progression, this.bpm);

  final String title;

  /// The key, in semitones above C.
  final int pitchClass;
  final Progression progression;

  /// Beats per minute, in 4/4.
  final int bpm;
}

/// The songs offered; none needs a flat or sharp key, so there is no
/// spelling to choose.
const exampleSongs = [
  ExampleSong('Autumn Leaves', 7, Progression.twoFiveOne, 120),
  ExampleSong('Blue Bossa', 0, Progression.minorTwoFiveOne, 140),
  ExampleSong('Twist and Shout', 2, Progression.oneFourFive, 124),
  ExampleSong('Stand by Me', 9, Progression.oneSixFourFive, 118),
  ExampleSong('Sweet Home Chicago', 4, Progression.blues, 100),
];
