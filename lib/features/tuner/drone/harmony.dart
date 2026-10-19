/// Chords and progressions for the drone, in pure (just) intervals so the
/// notes do not beat against each other, which is what you want when
/// checking intonation.
library;

/// The kind of a chord: its notes above the root as pure ratios, as
/// semitones, and as steps up the scale (2 for a third, 3 for a fourth, 6
/// for a seventh), which say what letter each note is written with.
enum ChordQuality {
  /// Major triad.
  major([1, 5 / 4, 3 / 2], [4, 7], [2, 4]),

  /// Minor triad.
  minor([1, 6 / 5, 3 / 2], [3, 7], [2, 4]),

  /// Dominant seventh, 7. The seventh is 16/9 (996 cents), the pure ratio
  /// closest to the minor seventh a bassist plays: the harmonic seventh,
  /// 7/4, would sound 31 cents flat of it.
  dominant([1, 5 / 4, 3 / 2, 16 / 9], [4, 7, 10], [2, 4, 6]),

  /// Major seventh, maj7 (15/8).
  major7([1, 5 / 4, 3 / 2, 15 / 8], [4, 7, 11], [2, 4, 6]),

  /// Minor seventh, m7 (9/5).
  minor7([1, 6 / 5, 3 / 2, 9 / 5], [3, 7, 10], [2, 4, 6]),

  /// Half-diminished seventh, m7♭5.
  halfDiminished([1, 6 / 5, 64 / 45, 16 / 9], [3, 6, 10], [2, 4, 6]),

  /// Diminished triad.
  diminished([1, 6 / 5, 64 / 45], [3, 6], [2, 4]),

  /// Suspended fourth, sus4: the fourth in place of the third.
  sus4([1, 4 / 3, 3 / 2], [5, 7], [3, 4]);

  const ChordQuality(this._ratios, this._semitones, this.letterSteps);

  final List<double> _ratios;
  final List<int> _semitones;

  /// How many letters above the root's each note above it is written.
  final List<int> letterSteps;

  /// Ratios to the root, the root first.
  List<double> get ratios => _ratios;

  /// The notes above the root, in semitones.
  List<int> get semitones => _semitones;
}

/// One chord of a progression: its root, in semitones above the key, its
/// quality and its Roman numeral.
class ProgressionStep {
  const ProgressionStep(this.offset, this.quality, this.numeral);

  final int offset;
  final ChordQuality quality;
  final String numeral;

  /// Steps up the scale from the key, 0 for I, 4 for V: which letter the
  /// root is written with. A ♭ before the numeral does not count.
  int get degree => const [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
  ].indexOf(numeral.replaceAll('♭', '').toUpperCase());
}

/// Standard progressions, one chord per bar, played over and over in the
/// key of the note touched. Jazz ones are in sevenths, the others in triads.
enum Progression {
  /// Major II–V–I: in C, Dm7 G7 Cmaj7.
  twoFiveOne([
    ProgressionStep(2, ChordQuality.minor7, 'II'),
    ProgressionStep(7, ChordQuality.dominant, 'V'),
    ProgressionStep(0, ChordQuality.major7, 'I'),
  ]),

  /// Minor II–V–I: in C, Dm7♭5 G7 Cm7.
  minorTwoFiveOne([
    ProgressionStep(2, ChordQuality.halfDiminished, 'II'),
    ProgressionStep(7, ChordQuality.dominant, 'V'),
    ProgressionStep(0, ChordQuality.minor7, 'I'),
  ], minor: true),

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
  ]),

  /// I–VI–II–V, the jazz turnaround: in C, Cmaj7 A7 Dm7 G7.
  oneSixTwoFive([
    ProgressionStep(0, ChordQuality.major7, 'I'),
    ProgressionStep(9, ChordQuality.dominant, 'VI'),
    ProgressionStep(2, ChordQuality.minor7, 'II'),
    ProgressionStep(7, ChordQuality.dominant, 'V'),
  ]),

  /// I–V–VI–IV: in C, C G Am F.
  oneFiveSixFour([
    ProgressionStep(0, ChordQuality.major, 'I'),
    ProgressionStep(7, ChordQuality.major, 'V'),
    ProgressionStep(9, ChordQuality.minor, 'VI'),
    ProgressionStep(5, ChordQuality.major, 'IV'),
  ]),

  /// Andalusian cadence, in a minor key: in A, Am G F E.
  andalusian([
    ProgressionStep(0, ChordQuality.minor, 'I'),
    ProgressionStep(10, ChordQuality.major, '♭VII'),
    ProgressionStep(8, ChordQuality.major, '♭VI'),
    ProgressionStep(7, ChordQuality.major, 'V'),
  ], minor: true);

  const Progression(this.steps, {this.minor = false});

  final List<ProgressionStep> steps;

  /// The key is minor.
  final bool minor;
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
  ExampleSong('Let It Be', 0, Progression.oneFiveSixFour, 72),
  ExampleSong('Hit the Road Jack', 9, Progression.andalusian, 168),
];
