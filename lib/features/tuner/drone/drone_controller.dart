import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../audio/piano_output.dart';
import '../../../audio/piano_sound.dart';
import '../../../audio/pitch.dart';
import '../../../audio/tone_output.dart';
import '../../metronome/feel.dart';
import '../../metronome/time_signature.dart';
import 'harmony.dart';

/// What the drone plays on its note: the note alone, a chord built on it,
/// or a progression in its key.
enum DroneVoicing { root, chord, progression }

/// How the drone plays on the piano, in time with the metronome's tempo and
/// time signature: the chord struck once a bar, on every beat, or one note
/// of it on every beat (an arpeggio).
enum DroneStyle {
  /// Struck on the "one" and left to ring.
  held(PianoStyle.bar),
  beat(PianoStyle.beat),
  arpeggio(PianoStyle.arpeggio);

  const DroneStyle(this.piano);

  final PianoStyle piano;
}

/// How the piano spreads a chord over the keys.
enum ChordShape {
  /// The notes stacked above the root, as the chord is spelled.
  stacked,

  /// The root as the bass, and the other notes close together above it, in
  /// one place on the keyboard whatever the chord: from one chord to the next
  /// they move as little as they can, as a pianist's hand does.
  close,

  /// As [close] but without the bass: the root is left to the bass player.
  rootless,
}

/// The chords offered in Chord mode.
enum ChordType {
  major(ChordQuality.major),
  minor(ChordQuality.minor),

  /// The dominant seventh: always with its seventh, which names it.
  seventh(ChordQuality.dominant);

  const ChordType(this.quality);

  final ChordQuality quality;
}

/// The length, position, tempo and time signature of the bar a progression
/// follows: the metronome's, so chords change on its "one". It notifies when
/// the tempo or the time signature change.
abstract interface class BarClock implements Listenable {
  /// Beats per minute of the figure the tempo counts: in 6/8, dotted
  /// quarters (see [TimeSignature.pulsesPerBeat]).
  int get bpm;
  TimeSignature get signature;

  /// How the beat is felt (swing): the piano follows it.
  MetronomeFeel get feel;

  Duration get barLength;

  /// How far into the bar it is, 0 to 1, or null when not counting.
  double? get barPhase;
}

/// 4/4 at 80 BPM, for when nothing else keeps time.
class _FixedBar implements BarClock {
  const _FixedBar();

  @override
  int get bpm => 80;

  @override
  TimeSignature get signature => TimeSignature.fourFour;

  @override
  MetronomeFeel get feel => MetronomeFeel.straight;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  Duration get barLength => const Duration(seconds: 3);

  @override
  double? get barPhase => null;
}

/// A chord as the drone plays it.
typedef DroneChord = ({int root, ChordQuality quality, bool seventh});

/// State and playback of the drone: the piano playing a note, a chord or a
/// progression, in time with the metronome, to practise on.
///
/// Without a piano (in tests) it falls back to a sustained tone.
class DroneController extends ChangeNotifier {
  DroneController(this._output, {BarClock? clock, this._piano})
    : _clock = clock ?? const _FixedBar() {
    _clock.addListener(_onClockChanged);
    _lastBpm = _clock.bpm;
    _lastSignature = _clock.signature;
    _lastFeel = _clock.feel;
  }

  final ToneOutput _output;
  final PianoOutput? _piano;
  final BarClock _clock;

  /// The drone opens in the middle octave (A4 = 440 Hz): high enough for any
  /// phone speaker, and easy to hear against a bass.
  static const defaultOctave = 4;

  /// The octaves it can play the root in: lower ones for a bass, to hear the
  /// beats against its note on headphones or a speaker that reaches them.
  static const octaves = [2, 3, 4];

  /// Loudness at full level.
  static const _fullVolume = 0.8;

  /// Set by the metronome / drone balance; the phone's volume buttons set
  /// how loud it all is.
  double _level = 1;

  double get _volume => _fullVolume * _level;

  bool _playing = false;
  bool _audioFailed = false;
  var _octave = defaultOctave;
  Note _note = const Note(9, defaultOctave);
  ChordShape _shape = ChordShape.close;
  DroneVoicing _voicing = DroneVoicing.root;
  ChordType _chord = ChordType.major;
  Progression _progression = Progression.twoFiveOne;
  bool _sevenths = false;
  DroneStyle _style = DroneStyle.beat;
  int _step = 0;
  Timer? _barTimer;

  // The piano keeps its own count of bars (see [_scheduleBar]): where in
  // its loop the clock started, and how long it waited for the metronome's
  // next bar line before the first chord.
  final _loopClock = Stopwatch();
  Duration _loopStartedAt = Duration.zero;
  Duration _loopWaiting = Duration.zero;
  late int _lastBpm;
  late TimeSignature _lastSignature;
  late MetronomeFeel _lastFeel;

  /// True when the next piano loop must start from its first chord, because
  /// what it plays has changed; false when only the tempo did, and it
  /// carries on from where it was.
  var _fromTheTop = true;
  double _a4 = 440;
  var _disposed = false;

  /// The latest sound change still under way, if any (see [_sync]).
  Future<void>? _pending;

  /// A change waiting for the one under way, if any: later changes join it
  /// rather than queue up behind it (see [_sync]).
  Future<void>? _queued;

  bool get isPlaying => _playing;

  /// True when the last attempt to start sound failed on this device.
  bool get audioFailed => _audioFailed;

  /// The note touched: the root, or the key of a progression.
  Note get note => _note;

  /// The octave the root is played in, one of [octaves].
  int get octave => _octave;

  /// How the piano spreads a chord (see [ChordShape]).
  ChordShape get shape => _shape;
  DroneVoicing get voicing => _voicing;
  ChordType get chord => _chord;
  Progression get progression => _progression;

  /// Whether chords and progressions add the seventh to their triads.
  bool get sevenths => _sevenths;

  DroneStyle get style => _style;

  /// True when the piano plays (always, bar in tests: see the class).
  bool get _patterned => _piano != null;

  /// Whether the piano can play at all (the styles are offered only then).
  bool get hasPiano => _piano != null;

  /// The chord of the progression playing now, 0 for the first.
  int get step => _step;
  double get a4 => _a4;

  /// The chord sounding (or that would sound), or null for the note alone.
  DroneChord? get currentChord => _chordAt(_step);

  /// The Roman numerals of the progression by the pitch class of the root
  /// they stand on ("II" on E in D, or "I · IV" where two chords share a
  /// root); empty outside a progression. They stay put while it plays: the
  /// circle shows where to go, not what is coming.
  Map<int, String> get degreeLabels {
    if (_voicing != DroneVoicing.progression) return const {};
    final labels = <int, List<String>>{};
    for (final step in _progression.steps) {
      final root = (_note.pitchClass + step.offset) % 12;
      final list = labels.putIfAbsent(root, () => []);
      if (!list.contains(step.numeral)) list.add(step.numeral);
    }
    return {for (final e in labels.entries) e.key: e.value.join(' · ')};
  }

  DroneChord? _chordAt(int step) => switch (_voicing) {
    DroneVoicing.root => null,
    DroneVoicing.chord => (
      root: _note.pitchClass,
      quality: _chord.quality,
      seventh: _sevenths || _chord == ChordType.seventh,
    ),
    // A dominant always has its seventh, as in Chord mode: it is what makes
    // it a dominant (the blues is all sevenths).
    DroneVoicing.progression => (
      root: (_note.pitchClass + _progression.steps[step].offset) % 12,
      quality: _progression.steps[step].quality,
      seventh:
          _sevenths ||
          _progression.steps[step].quality == ChordQuality.dominant,
    ),
  };

  /// The letter (0 = C … 6 = B) the key is written with: C♯ or D♭, F♯ or
  /// G♭ as chosen (see [toggleSpelling]), the usual one for the others.
  int get keyLetter =>
      letterOf(_note.pitchClass, flat: spelledFlat(_note.pitchClass));

  /// The letter of the chord root at [step], counted up the scale from the
  /// key, so that each chord of a progression is spelled as in its key: in
  /// C♯ minor, II–V–I is D♯ø G♯7 C♯m, not E♭ø A♭7 C♯m.
  int letterAt(int step) => _voicing == DroneVoicing.progression
      ? (keyLetter + _progression.steps[step].degree) % 7
      : keyLetter;

  /// The letter of the root sounding now.
  int get rootLetter => letterAt(_step);

  /// The black keys that may be written either way, C♯/D♭ and F♯/G♭, and
  /// which of them are written with a flat.
  static const respellable = {1, 6};
  final _flats = <int>{};

  /// True when [pitchClass] is written with a flat (D♭, G♭).
  bool spelledFlat(int pitchClass) => _flats.contains(pitchClass);

  /// Writes [pitchClass] the other way, C♯ as D♭ and back, if it can be.
  void toggleSpelling(int pitchClass) {
    if (!respellable.contains(pitchClass)) return;
    if (!_flats.remove(pitchClass)) _flats.add(pitchClass);
    _notify();
  }

  static const _majorScale = [0, 2, 4, 5, 7, 9, 11];
  static const _minorScale = [0, 2, 3, 5, 7, 8, 10];

  /// Whether the circle shows the key: with a progression selected, the
  /// note chosen is its key, playing or not.
  bool get showsKey => _voicing == DroneVoicing.progression;

  /// The key is minor: the minor II–V–I (the other progressions are major).
  bool get keyIsMinor => _progression == Progression.minorTwoFiveOne;

  /// The seven notes of the key (natural minor for a minor key), as pitch
  /// classes; empty when the circle shows no key.
  Set<int> get keyNotes => showsKey
      ? {
          for (final s in keyIsMinor ? _minorScale : _majorScale)
            (_note.pitchClass + s) % 12,
        }
      : const {};

  /// The letter (0 = C … 6 = B) [pitchClass] is written with in the key, so
  /// that each letter is used once (G♭ major has C♭, not B), or null if the
  /// note is not in the key.
  int? keyLetterOf(int pitchClass) {
    if (!showsKey) return null;
    final degree = (keyIsMinor ? _minorScale : _majorScale).indexOf(
      (pitchClass - _note.pitchClass + 12) % 12,
    );
    return degree < 0 ? null : (keyLetter + degree) % 7;
  }

  /// The root sounding now: the note, or the root of the current chord.
  int get rootPitchClass => currentChord?.root ?? _note.pitchClass;

  /// Frequency of the root sounding, in Hz.
  double get frequency => Note(rootPitchClass, _octave).frequency(a4: _a4);

  /// The pitch classes of the other notes of the chord sounding.
  Set<int> get chordTones {
    final c = currentChord;
    if (c == null) return const {};
    return {
      for (final s in c.quality.semitones(seventh: c.seventh))
        (c.root + s) % 12,
    };
  }

  /// Frequencies currently sounding: the root, then the rest of the chord.
  List<double> get frequencies => _frequenciesOf(currentChord);

  List<double> _frequenciesOf(DroneChord? c) {
    final root = Note(c?.root ?? _note.pitchClass, _octave).frequency(a4: _a4);
    final ratios = c == null ? [1.0] : c.quality.ratios(seventh: c.seventh);
    return [for (final r in ratios) root * r];
  }

  /// The root a little louder than the notes above it.
  static List<double> _gainsFor(int voices) => [
    for (var i = 0; i < voices; i++) i == 0 ? 1.0 : 0.7,
  ];

  Future<void> start() {
    _playing = true;
    _audioFailed = false;
    _step = 0;
    _fromTheTop = true;
    _notify();
    _prepareProgression();
    _scheduleBar();
    return _sync();
  }

  Future<void> stop() {
    _playing = false;
    _barTimer?.cancel();
    _loopClock.stop();
    _notify();
    return _sync();
  }

  Future<void> toggle() => _playing ? stop() : start();

  /// What a note key does: plays [pitchClass], switches to it if another
  /// note is playing, or stops it if it is the one already playing.
  Future<void> tapNote(int pitchClass) {
    if (_playing && _note.pitchClass == pitchClass) return stop();
    setPitchClass(pitchClass);
    return _playing ? Future.value() : start();
  }

  void setPitchClass(int pitchClass) {
    if (pitchClass == _note.pitchClass) return;
    _update(() => _note = Note(pitchClass, _octave), restart: true);
  }

  void setOctave(int octave) {
    if (octave == _octave || !octaves.contains(octave)) return;
    _update(() {
      _octave = octave;
      _note = Note(_note.pitchClass, octave);
    });
  }

  void setShape(ChordShape shape) {
    if (shape == _shape) return;
    _update(() => _shape = shape);
  }

  void setVoicing(DroneVoicing voicing) {
    if (voicing == _voicing) return;
    _update(() => _voicing = voicing, restart: true);
  }

  void setChord(ChordType chord) {
    if (chord == _chord) return;
    _update(() => _chord = chord);
  }

  void setProgression(Progression progression) {
    if (progression == _progression) return;
    _update(() => _progression = progression, restart: true);
  }

  void setSevenths(bool sevenths) {
    if (sevenths == _sevenths) return;
    _update(() => _sevenths = sevenths);
  }

  void setStyle(DroneStyle style) {
    if (style == _style) return;
    _update(() => _style = style, restart: true);
  }

  /// Sets the level from the metronome / drone balance, 0 to 1.
  void setLevel(double level) {
    final value = level.clamp(0.0, 1.0);
    if (value == _level) return;
    _level = value;
    if (_playing && !_disposed) {
      try {
        _output.setVolume(_volume);
        _piano?.setVolume(_volume);
      } catch (error) {
        debugPrint('Drone level could not change: $error');
      }
    }
  }

  void setReferencePitch(double a4) {
    if (a4 == _a4) return;
    _update(() => _a4 = a4, carryOn: true);
  }

  /// Applies [change]; with [restart], a progression starts again from its
  /// first chord.
  void _update(
    VoidCallback change, {
    bool restart = false,
    bool carryOn = false,
  }) {
    change();
    if (restart) _step = 0;
    if (!carryOn) _fromTheTop = true;
    _notify();
    if (!_playing) return;
    _prepareProgression();
    if (restart) _scheduleBar();
    _sync();
  }

  /// Gets every chord of the progression ready, so each change of chord
  /// sounds on time.
  void _prepareProgression() {
    if (_voicing != DroneVoicing.progression || _patterned) return;
    final chords = [
      for (var i = 0; i < _progression.steps.length; i++)
        _frequenciesOf(_chordAt(i)),
    ];
    _output
        .prepare([for (final f in chords) (f, _gainsFor(f.length))])
        .catchError((Object error) {
          debugPrint('Drone could not prepare the progression: $error');
        });
  }

  /// Moves to the next chord at the next bar line.
  ///
  /// Held as one tone, the bar line is the metronome's "one" when it is
  /// counting, otherwise a bar of its tempo from now. On the piano, it is
  /// the loop's own: its first chord sounds on a bar line of the metronome
  /// (when it plays), and one chord follows each bar from there.
  void _scheduleBar() {
    _barTimer?.cancel();
    if (!_playing || _voicing != DroneVoicing.progression) return;
    final bar = _clock.barLength;
    Duration wait;
    if (_patterned) {
      final elapsed = _loopClock.elapsed;
      if (elapsed < _loopWaiting) {
        // Still waiting to come in: the first chord is up on the screen.
        wait = _loopWaiting + bar - elapsed;
      } else {
        final at = _loopStartedAt + elapsed - _loopWaiting;
        wait =
            bar -
            Duration(microseconds: at.inMicroseconds % bar.inMicroseconds);
      }
      if (wait < const Duration(milliseconds: 40)) wait += bar;
    } else {
      final phase = _clock.barPhase;
      wait = phase == null ? bar : bar * (1 - phase);
      // Just after a bar line, wait for the next one rather than cut short
      // the chord that has only just started.
      if (wait < const Duration(milliseconds: 150)) wait += bar;
    }
    _barTimer = Timer(wait, () {
      if (!_playing || _disposed) return;
      _step = (_step + 1) % _progression.steps.length;
      _notify();
      if (!_patterned) _sync();
      _scheduleBar();
    });
  }

  /// The metronome changed its tempo, its time signature or its feel: the
  /// piano follows, carrying on from where it was for a change of tempo or
  /// feel, from the top of the bar for another time signature.
  void _onClockChanged() {
    final bpm = _clock.bpm, signature = _clock.signature;
    final feel = _clock.feel;
    final changed =
        bpm != _lastBpm || signature != _lastSignature || feel != _lastFeel;
    if (signature != _lastSignature) _fromTheTop = true;
    _lastBpm = bpm;
    _lastSignature = signature;
    _lastFeel = feel;
    if (!changed || !_playing || !_patterned || _disposed) return;
    _sync();
  }

  /// The chords of the loop, one per bar, as the piano plays them.
  List<PianoChord> get _pianoChords {
    final bass = (_octave + 1) * 12;
    // Where the notes above the bass sit in [ChordShape.close]: one octave of
    // keys, from here up, the same for every chord (G3, C4 or E4, to clear
    // the bass).
    final floor = _octave <= 2
        ? 55
        : _octave == 3
        ? 60
        : 64;

    List<int> notes(DroneChord? c) {
      // A single note: the piano plays the root alone.
      if (c == null) return [bass + _note.pitchClass];
      final root = bass + c.root;
      final above = c.quality.semitones(seventh: c.seventh);
      if (_shape == ChordShape.stacked) {
        return [root, for (final s in above) root + s];
      }
      // Each note on the key of its name within the octave from the floor:
      // whatever the chord, the hand stays in one place.
      final upper = [for (final s in above) floor + (c.root + s - floor) % 12]
        ..sort();
      return _shape == ChordShape.rootless ? upper : [root, ...upper];
    }

    return [
      if (_voicing == DroneVoicing.progression)
        for (var i = 0; i < _progression.steps.length; i++) notes(_chordAt(i))
      else
        notes(_chordAt(0)),
    ];
  }

  /// Brings the sound in line with [isPlaying] and the current settings.
  ///
  /// Starts and retunes run one after the other, each reading the state
  /// when its turn comes, so two quick changes never mix their voices; the
  /// first one starts at once, so sound begins without delay. Stopping
  /// happens at once too, and a start still under way stops again as soon
  /// as it is done, so a stop pressed while the audio engine is starting
  /// really silences it. Never throws: a failure shows in [audioFailed].
  ///
  /// Changes made while one is under way are applied all at once when it is
  /// done, as the metronome does: holding + renders the piano only as often
  /// as it can, always with the latest tempo, instead of catching up with
  /// every step in turn.
  Future<void> _sync() {
    if (!_playing || _disposed) return _silence();
    // The change already waiting reads the state when its turn comes, so it
    // takes this one in too.
    if (_queued case final queued?) return queued;
    final previous = _pending;
    final Future<void> done;
    if (previous == null) {
      done = _play();
    } else {
      late final Future<void> next;
      next = previous.then((_) {
        // Its turn: from now on, a change waits for it to finish.
        if (identical(_queued, next)) _queued = null;
        return _play();
      });
      done = _queued = next;
    }
    late final Future<void> tracked;
    tracked = done.whenComplete(() {
      if (identical(_pending, tracked)) _pending = null;
    });
    return _pending = tracked;
  }

  Future<void> _play() async {
    if (!_playing || _disposed) return;
    try {
      if (_patterned) {
        await _playPiano();
      } else {
        // Not awaited when there is no piano: sound starts without delay.
        final piano = _piano;
        if (piano != null) await piano.stop();
        final f = frequencies;
        await _output.play(f, _gainsFor(f.length), _volume);
      }
    } catch (error) {
      debugPrint('Drone could not start: $error');
      _playing = false;
      _audioFailed = true;
      _barTimer?.cancel();
      _notify();
    }
    // Stopped (or failed) while starting: voices that only started now
    // must not keep sounding unseen.
    if (!_playing || _disposed) await _silence();
  }

  /// Starts (or replaces) the piano's loop, and lines the chord shown up
  /// with it.
  Future<void> _playPiano() async {
    final fromTheTop = _fromTheTop;
    _fromTheTop = false;
    final chords = _pianoChords;
    final bpm = _lastBpm = _clock.bpm;
    final signature = _lastSignature = _clock.signature;
    final feel = _lastFeel = _clock.feel;
    final started = await _piano!.play(
      chords: chords,
      // A note on its own is kept sounding, whatever the style.
      style: _voicing == DroneVoicing.root ? PianoStyle.drone : _style.piano,
      // The piano counts pulses, like the clicks: three a beat in 6/8.
      bpm: bpm * signature.pulsesPerBeat,
      signature: signature,
      a4: _a4,
      volume: _volume,
      startAt: fromTheTop ? Duration.zero : null,
      rootless: _voicing != DroneVoicing.root && _shape == ChordShape.rootless,
      feel: feel,
    );
    if (!_playing || _disposed) return;
    final bar = _clock.barLength;
    _loopStartedAt = started.position;
    _loopWaiting = started.delay;
    _loopClock
      ..reset()
      ..start();
    if (_voicing == DroneVoicing.progression) {
      // Waiting for the metronome, the first chord is still to come.
      _step = started.delay > Duration.zero
          ? 0
          : started.position.inMicroseconds ~/
                bar.inMicroseconds %
                chords.length;
      _notify();
      _scheduleBar();
    }
  }

  Future<void> _silence() async {
    try {
      await _output.stop();
      final piano = _piano;
      if (piano != null) await piano.stop();
    } catch (error) {
      debugPrint('Drone could not stop: $error');
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _playing = false;
    _barTimer?.cancel();
    _clock.removeListener(_onClockChanged);
    _sync();
    super.dispose();
  }
}
