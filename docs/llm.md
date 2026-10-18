# Low End for assistants and language models

Low End is built "LLM first": everything a player can do on screen is also an **action** with a name, JSON arguments and a JSON answer, so an assistant can tune, start a piano chord or read the tuner just like a finger can.

The actions live in [`lib/actions/app_actions.dart`](../lib/actions/app_actions.dart). The screens use the same controllers, so the two can never drift apart. The full catalog, in the tool format used by MCP and by the Claude, Gemini and OpenAI APIs, is in [`llm-actions.json`](llm-actions.json). It is generated from the code by `exportActions()` and a test keeps it in sync: after changing an action, run `flutter test test/app_actions_test.dart --update-goldens` to rewrite it.

## How the app behaves

Three sections: **Metronome**, **Harmony** (Armonia) and **Tuner**. Harmony keeps its original names in the actions: `drone_play`, `drone_stop`, `drone_set` and the section id `drone`. Know these rules before calling anything:

- **Each sound has its own switch.** The metronome, Harmony and the tuner are started and stopped on their own, from their own section (the middle of the dial). The tabs and the swipes only move between sections.
- **A start action opens its section.** `metronome_start` shows the metronome, `drone_play` shows Harmony, `tuner_start` shows the tuner. Stop actions (`metronome_stop`, `drone_stop`, `tuner_stop`) and all the `*_set` actions stay on the current section.
- **Metronome and Harmony can play together**, in time with each other: Harmony follows the tempo and time signature of the metronome. If one is already playing when the other starts, the new one waits for the next bar line of the first and a countdown is shown on screen. The answer comes back at once with `playing: true`, even during the wait. Stopping during the wait cancels the start.
- **The tuner listens through the microphone, so it cannot share the room with the other two.** It listens only while its section is on screen (it stops by itself when another section or the settings page opens, or the app goes to the background).
  - `open_section` with `tuner` does *not* stop anything: the tuner starts listening only if neither the metronome nor Harmony is playing, and not if it was paused with `tuner_stop`.
  - `tuner_start` always listens. If the metronome or Harmony is playing, it is **paused** (not forgotten): the player sees a notice with a "Resume" button, as when touching the tuner's dial. Nothing resumes by itself, and no action resumes it either: call `metronome_start` / `drone_play` again (which also leaves the tuner).
  - `tuner_stop` pauses the tuner like the Pause button: it stays paused, also when coming back to the section, until `tuner_start` or a touch on the dial.
  - `metronome_start` and `drone_play` leave the tuner, so its microphone turns off.
- **Locking the gestures** ("Blocca i gesti" in the settings) only disables swiping between sections. Actions, including `open_section`, still work.
- Loudness follows the phone's media volume; there is no volume or balance action. The sound is a piano in equal temperament; the metronome has no settable time signature in actions (state reports it as `time_signature`).
- The app is always dark (bronze theme); there is no theme setting.

## Actions

| Action | Arguments | What it does |
|---|---|---|
| `get_state` | none | Changes nothing. Returns the section on screen, the tuner (status `idle`, `starting`, `listening`, `permissionDenied` or `failed`; the last reading with target note, played note, `written` note for a transposing instrument, frequency, cents, `in_tune`), Harmony (`playing`, note, voicing, chord, progression, style, sevenths, `progression_step`, `audio_failed`), the metronome (`playing`, `bpm`, `time_signature`, `subdivision`, `backbeat`) and the settings (reference A, language, note names, transposition) |
| `open_section` | `section`: `tuner`, `drone` (Harmony) or `metronome` | Shows the section. Starts and stops nothing, except the tuner's microphone as described above |
| `tuner_start` | none | Opens the tuner and listens; pauses the metronome and Harmony if they play. The answer says `listening`, or `permissionDenied` / `failed` |
| `tuner_stop` | none | Pauses the tuner and turns the microphone off, until `tuner_start` |
| `drone_play` | all optional: `note`, `voicing`, `chord`, `progression`, `style`, `sevenths` | Opens Harmony, applies the arguments and plays the piano if it was not playing (if it was, only the arguments change). See below for the values |
| `drone_stop` | none | Stops Harmony, also during the countdown |
| `drone_set` | same as `drone_play` | Changes Harmony without starting, stopping or changing section |
| `metronome_start` | all optional: `bpm`, `subdivision`, `backbeat` | Opens the metronome, applies the arguments and starts it if it was not playing, in its current time signature |
| `metronome_stop` | none | Stops the metronome, also during the countdown |
| `metronome_set` | `bpm`, `subdivision`, `backbeat` (at least one) | Changes the metronome without starting, stopping or changing section. Remembered for the next launch |
| `set_reference_pitch` | `hz` (required) | A4: a whole number of hertz from 415 to 445, shared by tuner and Harmony, saved in the settings |
| `settings_set` | all optional: `language`, `note_names`, `transposition` | App `language` (`system`, `en`, `it`), `note_names` (`auto`, `solfege`, `letters`) and the `transposition` of the chromatic tuner (`c`, `bFlat`, `eFlat`, `f`). If one value is wrong none is applied |

Values:

- `note`: A, Bb, F#, or La, Sib, Fa#. Harmony always plays the middle octave (A4 = 440 Hz), so an octave number is ignored. It is the root, or the key of a progression.
- `voicing`: `root` (the note alone), `chord`, `progression`.
- `chord` (with voicing `chord`): `major`, `minor`, `seventh` (dominant seventh).
- `progression` (with voicing `progression`): `twoFiveOne`, `minorTwoFiveOne`, `oneFourFive`, `oneSixFourFive`, `blues`. One chord per bar, at the metronome tempo.
- `style`: `held` (struck once a bar), `beat` (on every beat), `arpeggio` (one note a beat). A `root` voicing is always sustained.
- `sevenths`: adds the seventh to chords and progressions (maj7, m7, 7, m7b5).
- `bpm`: a whole number from 30 to 250, or to 400 in 7/8. It counts the beat of the current time signature (quarters in x/4, dotted quarters in 6/8, 9/8, 12/8, eighths in 7/8), so the same number can be refused after the signature changes.
- `subdivision`: `quarters`, `eighths`, `swing_eighths`, `triplets`, `sixteenths`, `swing_sixteenths`. Only heard in bars counted in quarters.
- `backbeat`: `true` clicks only on beats 2 and 4. Only heard in 2/4 and 4/4.

Arguments are checked before anything changes: a call with one wrong argument does nothing. Every answer is `{"ok": true, "state": {...}}` or `{"ok": false, "error": "..."}`, with an error message an assistant can read and fix. Unknown names and unknown parameters are errors.

## Calling them today: action links

On Android the app opens links of the form

```
lowend://action/<action>?<argument>=<value>&...
```

for example `lowend://action/drone_play?note=D&voicing=chord&chord=minor` or `lowend://action/tuner_start`. Any assistant, shortcut or automation app that can open a link can use them (on Android, for example, Tasker, a home-screen shortcut, or `adb shell am start -d "lowend://action/drone_stop"` to try it).

- Values are read as text and converted by the type in the catalog: numbers for `bpm` and `hz`, and `true`/`false` (also `1`/`0`, `yes`/`no`) for booleans.
- Write sharps as `%23` (`note=F%23`) or use `b` for flats and `♯`; a bare `#` starts a fragment and cuts the link.
- A link opens the app if it is closed. A link gives no answer to the caller: to read the result, use an integration that calls the actions and gets the JSON (see below).
- Links can only do what the buttons do, and the same rules apply: `tuner_start` brings the tuner to the front, listens and pauses the metronome and Harmony; the microphone never listens with the tuner off screen.

## Next steps

1. **Android App Functions** (Android 16 and later): publish the same actions to the system so Gemini and other assistants can call them and read the answer, through a small Kotlin layer that forwards to the Dart actions.
2. **MCP server** (optional, for desktop assistants such as Claude): only if someone needs it, since it would need a network connection, which the app avoids today.

## AI Act

Exposing actions to an assistant does not make Low End an AI system: the assistant (Gemini, Claude…) is the AI system and its provider carries the obligations. Low End would change category only if it shipped its own model, for example a built-in chatbot. Then it would have to tell users they are talking to an AI (Article 50), an obligation that applies to free and open-source software too.
