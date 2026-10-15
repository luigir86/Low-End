import 'dart:convert';

import '../app/app_navigation.dart';
import '../app/settings.dart';
import '../audio/pitch.dart';
import '../features/tuner/drone/drone_controller.dart';
import '../features/tuner/tuner_controller.dart';
import '../features/tuner/tunings.dart';

/// One thing the app can do, described so a language model (or any other
/// program) can find it, call it and understand the answer.
///
/// [parameters] is a JSON Schema object, the format used for tools by MCP and
/// by the Claude, Gemini and OpenAI APIs.
class AppAction {
  const AppAction({
    required this.name,
    required this.description,
    this.parameters = const {},
    this.required = const [],
  });

  final String name;
  final String description;
  final Map<String, Map<String, Object?>> parameters;
  final List<String> required;

  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'input_schema': {
      'type': 'object',
      'properties': parameters,
      if (required.isNotEmpty) 'required': required,
      'additionalProperties': false,
    },
  };
}

/// An action was called with arguments it cannot use.
class ActionError implements Exception {
  ActionError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The app's action layer: everything a player can do on screen, available
/// as named actions with JSON arguments and a JSON answer.
///
/// The screens and the outside world (deep links today; Android App
/// Functions, Siri Shortcuts or an MCP server later) go through the same
/// controllers, so an assistant can do anything a finger can. Every answer
/// carries the full [state], so the caller always knows where things stand.
class AppActions {
  AppActions({
    required this.drone,
    required this.tuner,
    required this.navigation,
    required this.settings,
  });

  final DroneController drone;
  final TunerController tuner;
  final AppNavigation navigation;
  final AppSettings settings;

  static const _note = {
    'type': 'string',
    'description':
        'Note name in English (A, Bb, F#) or Italian (La, Sib, Fa#). The '
        'drone always plays it in the middle octave (A4 = 440 Hz), so an '
        'octave number, if given, is ignored.',
  };

  static final catalog = <AppAction>[
    const AppAction(
      name: 'get_state',
      description:
          'Returns what the app is doing now: the section on screen, the '
          'tuner (listening, last note heard and how many cents off), '
          'the drone (playing, note, root or chord) and the settings '
          '(reference A, language, note names). Loudness follows the '
          "phone's media volume.",
    ),
    const AppAction(
      name: 'open_section',
      description: 'Shows a section of the app.',
      parameters: {
        'section': {
          'type': 'string',
          'enum': ['tuner', 'drone', 'metronome'],
        },
      },
      required: ['section'],
    ),
    const AppAction(
      name: 'tuner_start',
      description:
          'Opens the chromatic tuner and starts listening through the '
          'microphone: it recognises any note played. The tuner stops by '
          'itself when another section or the settings page opens, or the '
          'app goes to the background. Read the note with get_state.',
    ),
    const AppAction(
      name: 'tuner_stop',
      description:
          'Pauses the tuner and turns the microphone off. It stays paused, '
          'also when its section or the app comes back, until tuner_start.',
    ),
    const AppAction(
      name: 'drone_play',
      description:
          'Plays the drone, a sustained pure tone to practise intonation on. '
          'Any setting given is applied first.',
      parameters: _droneParameters,
    ),
    const AppAction(name: 'drone_stop', description: 'Stops the drone.'),
    const AppAction(
      name: 'drone_set',
      description:
          'Changes the drone settings without starting or stopping it.',
      parameters: _droneParameters,
    ),
    AppAction(
      name: 'set_reference_pitch',
      description:
          'Sets the frequency of A4, shared by the tuner and the drone, '
          'and saves it in the settings.',
      parameters: {
        'hz': {
          'type': 'number',
          'enum': referencePitches,
          'description': 'Frequency of A4 in Hz.',
        },
      },
      required: ['hz'],
    ),
    const AppAction(
      name: 'settings_set',
      description:
          'Changes and saves the app settings: the language of the app and '
          'how note names are written.',
      parameters: {
        'language': {
          'type': 'string',
          'enum': ['system', 'en', 'it'],
          'description': 'App language; "system" follows the phone.',
        },
        'note_names': {
          'type': 'string',
          'enum': ['auto', 'solfege', 'letters'],
          'description':
              '"solfege" is Do Re Mi with Italian octave numbers (La3 = 440 '
              'Hz), "letters" is C D E (A4 = 440 Hz), "auto" follows the '
              'app language.',
        },
      },
    ),
  ];

  static const _droneParameters = {
    'note': _note,
    'voicing': {
      'type': 'string',
      'enum': ['root', 'chord'],
      'description': 'The note alone, or the chord built on it.',
    },
    'chord': {
      'type': 'string',
      'enum': ['major', 'minor', 'seventh'],
      'description':
          'The chord played when voicing is "chord", in pure intervals; '
          '"seventh" is the dominant seventh, its seventh tuned to 16/9 (the '
          'pure ratio closest to the equal-tempered minor seventh).',
    },
  };

  /// Runs the action [name] and returns `{ok: true, state: …}`, or
  /// `{ok: false, error: …}` when the name or the arguments are wrong.
  Future<Map<String, Object?>> call(
    String name, [
    Map<String, Object?> args = const {},
  ]) async {
    try {
      final action = catalog.where((a) => a.name == name).firstOrNull;
      if (action == null) throw ActionError('Unknown action "$name".');
      for (final key in args.keys) {
        if (!action.parameters.containsKey(key)) {
          throw ActionError('"$name" has no parameter "$key".');
        }
      }
      for (final key in action.required) {
        if (args[key] == null) throw ActionError('"$name" needs "$key".');
      }
      await _run(name, args);
      return {'ok': true, 'state': state()};
    } on ActionError catch (error) {
      return {'ok': false, 'error': error.message};
    }
  }

  Future<void> _run(String name, Map<String, Object?> args) async {
    switch (name) {
      case 'get_state':
        break;
      case 'open_section':
        navigation.open(_enum(AppSection.values, args['section']));
      case 'tuner_start':
        navigation.open(AppSection.tuner);
        // Opening the tab already starts the tuner; waiting for that start
        // means the answer says "listening" (or why not), not "starting".
        await tuner.start();
      case 'tuner_stop':
        // Like the Pause button: the tuner stays paused when its tab or the
        // app comes back.
        await tuner.pause();
      case 'drone_play':
        _droneChange(args)();
        if (!drone.isPlaying) await drone.start();
      case 'drone_stop':
        await drone.stop();
      case 'drone_set':
        _droneChange(args)();
      case 'set_reference_pitch':
        final hz = _number(args['hz'], 'hz');
        if (!referencePitches.contains(hz)) {
          throw ActionError('"hz" must be one of $referencePitches.');
        }
        settings.setReferencePitch(hz);
      case 'settings_set':
        // Everything is checked before anything changes, so a call refused
        // for one argument leaves the others as they were.
        final language = args['language'];
        final code = switch (language) {
          null || 'system' => null,
          'en' || 'it' => language as String,
          _ => throw ActionError('"language" must be system, en or it.'),
        };
        final naming = args['note_names'] == null
            ? null
            : _enum(NoteNaming.values, args['note_names']);
        if (language != null) settings.setLanguage(code);
        if (naming != null) settings.setNaming(naming);
    }
  }

  /// Checks the drone arguments and returns the change they ask for, to be
  /// made only once all of them are known to be good.
  void Function() _droneChange(Map<String, Object?> args) {
    int? pitchClass;
    if (args['note'] case final Object note) {
      pitchClass =
          parseNote('$note')?.pitchClass ??
          (throw ActionError('Unknown note "$note".'));
    }
    final voicing = args['voicing'] == null
        ? null
        : _enum(DroneVoicing.values, args['voicing']);
    final chord = args['chord'] == null
        ? null
        : _enum(ChordType.values, args['chord']);
    return () {
      if (pitchClass != null) drone.setPitchClass(pitchClass);
      if (voicing != null) drone.setVoicing(voicing);
      if (chord != null) drone.setChord(chord);
    };
  }

  /// Everything an assistant needs to know about the app right now.
  Map<String, Object?> state() {
    final hz = tuner.frequency;
    final reading = hz == null
        ? null
        : TunerReading.of(hz, tuning: tuner.tuning, a4: settings.a4);
    return {
      'section': navigation.section.name,
      'settings': {
        'reference_pitch_hz': settings.a4,
        'language': settings.languageCode ?? 'system',
        'note_names': settings.naming.name,
      },
      'tuner': {
        'status': tuner.status.name,
        'reading': reading == null
            ? null
            : {
                'target': noteId(reading.target),
                'played': noteId(reading.played),
                'frequency_hz': _round(reading.frequency),
                'cents': _round(reading.cents),
                'in_tune': reading.inTune,
              },
      },
      'drone': {
        'playing': drone.isPlaying,
        'note': noteId(drone.note),
        'frequency_hz': _round(drone.frequency),
        'voicing': drone.voicing.name,
        'chord': drone.chord.name,
        'audio_failed': drone.audioFailed,
      },
      'metronome': {'available': false},
    };
  }

  /// Turns `lowend://action/drone_play?note=A` (or just its path,
  /// `/drone_play?note=A`, as Flutter hands deep links over) into an
  /// action name and its arguments, or null when it isn't an action link.
  static (String, Map<String, Object?>)? parseLink(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final name = segments.last;
    final action = catalog.where((a) => a.name == name).firstOrNull;
    if (action == null) return null;
    return (
      name,
      {
        for (final MapEntry(:key, :value) in uri.queryParameters.entries)
          key: switch (action.parameters[key]?['type']) {
            'integer' || 'number' => num.tryParse(value) ?? value,
            'boolean' => switch (value) {
              'true' || '1' || 'yes' => true,
              'false' || '0' || 'no' => false,
              _ => value,
            },
            _ => value,
          },
      },
    );
  }

  static double _round(double v) => (v * 10).round() / 10;

  static T _enum<T extends Enum>(List<T> values, Object? name) =>
      values.where((v) => v.name == name).firstOrNull ??
      (throw ActionError(
        '"$name" must be one of ${values.map((v) => v.name).join(', ')}.',
      ));

  static double _number(Object? v, String key) =>
      v is num ? v.toDouble() : (throw ActionError('"$key" must be a number.'));
}

const _sharpNames = [
  'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B', //
];

/// A note as plain ASCII, such as "Bb1", easy for programs to read.
String noteId(Note n) => '${_sharpNames[n.pitchClass]}${n.octave}';

const _letters = {'c': 0, 'd': 2, 'e': 4, 'f': 5, 'g': 7, 'a': 9, 'b': 11};
const _solfege = {
  'do': 0,
  're': 2,
  'mi': 4,
  'fa': 5,
  'sol': 7,
  'la': 9,
  'si': 11,
};

/// Reads a note name in English or Italian, with an optional sharp or flat
/// and octave: "A", "Bb2", "F♯", "La", "Sib1", "do#". The octave is null when
/// not given.
({int pitchClass, int? octave})? parseNote(String text) {
  final match = RegExp(
    r'^\s*(do|re|mi|fa|sol|la|si|[a-g])\s*(#|♯|b|♭)?\s*(-?\d)?\s*$',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) return null;
  final name = match[1]!.toLowerCase();
  var pitchClass = _solfege[name] ?? _letters[name]!;
  pitchClass += switch (match[2]) {
    '#' || '♯' => 1,
    'b' || '♭' => -1,
    _ => 0,
  };
  final octave = match[3] == null ? null : int.parse(match[3]!);
  return (pitchClass: pitchClass % 12, octave: octave);
}

/// The action catalog as JSON, published in `docs/llm-actions.json` for
/// assistants and the people who connect them.
String exportActions() =>
    '${const JsonEncoder.withIndent('  ').convert([for (final a in AppActions.catalog) a.toJson()])}\n';
