# Low End for assistants and language models

Low End is built "LLM first": everything a player can do on screen is also an **action** with a name, JSON arguments and a JSON answer, so an assistant can tune, start a drone or read the tuner just like a finger can.

The actions live in [`lib/actions/app_actions.dart`](../lib/actions/app_actions.dart). The screens use the same controllers, so the two can never drift apart. The full catalog, in the tool format used by MCP and by the Claude, Gemini and OpenAI APIs, is in [`llm-actions.json`](llm-actions.json) (a test keeps it in sync with the code).

## Actions

The section the app shows as **Harmony** (Armonia) keeps its original action names: `drone_play`, `drone_stop`, `drone_set` and the section id `drone`.

| Action | What it does |
|---|---|
| `get_state` | Section on screen, tuner (status, last note, cents off, in tune), drone (playing, note, root or chord), settings (reference A, language, note names) |
| `open_section` | Shows `tuner`, `drone` or `metronome` |
| `tuner_start` | Opens the chromatic tuner and listens: it names any note played |
| `tuner_stop` | Pauses the tuner, like the Pause button: it stays paused until `tuner_start` |
| `drone_play` | Plays the drone in the middle octave, applying `note` (A, Bb, Sol…: the root, or the key of a progression), `voicing` (`root`, `chord` or `progression`), `chord` (`major`, `minor`, `seventh`), `progression` (`twoFiveOne`, `minorTwoFiveOne`, `oneFourFive`, `oneSixFourFive`, `blues`; one chord per bar at the metronome tempo) and `style` (`held`, `beat`, `arpeggio`: the piano strikes the chord once a bar, on every beat, or plays an arpeggio, at the metronome tempo and time signature) and `sevenths` (adds the seventh: maj7, m7, 7, m7b5). The sound is a piano, in equal temperament |
| `drone_stop` | Stops the drone |
| `metronome_start` | Opens the metronome and starts it in 4/4, optionally at `bpm` (30–250) |
| `metronome_stop` | Stops the metronome |
| `metronome_set` | Sets the tempo (`bpm`), the `subdivision` (`none`, `eighths`, `triplets`, `sixteenths`, `swing`) or the click on 2 and 4 (`backbeat`), without starting or stopping it |
| `drone_set` | Changes the drone settings without starting or stopping it |
| `set_reference_pitch` | A4: a whole number of hertz from 415 to 445, saved in the settings |
| `settings_set` | App `language` (`system`, `en`, `it`), `note_names` (`auto`, `solfege`, `letters`) and the `transposition` of the chromatic tuner (`c`, `bFlat`, `eFlat`, `f`) |

Every answer is `{"ok": true, "state": {...}}` or `{"ok": false, "error": "..."}`, with an error message an assistant can read and fix.

## Calling them today: action links

On Android the app opens links of the form

```
lowend://action/<action>?<argument>=<value>&...
```

for example `lowend://action/drone_play?note=D&voicing=chord&chord=minor` or `lowend://action/tuner_start`. Any assistant, shortcut or automation app that can open a link can use them (on Android, for example, Tasker, a home-screen shortcut, or `adb shell am start -d "lowend://action/drone_stop"` to try it).

Links can only do what the buttons do. The microphone still listens only while the tuner is on screen, so `tuner_start` brings the tuner to the front.

## Next steps

1. **Android App Functions** (Android 16 and later): publish the same actions to the system so Gemini and other assistants can call them and read the answer, through a small Kotlin layer that forwards to the Dart actions.
2. **MCP server** (optional, for desktop assistants such as Claude): only if someone needs it, since it would need a network connection, which the app avoids today.

## AI Act

Exposing actions to an assistant does not make Low End an AI system: the assistant (Gemini, Claude…) is the AI system and its provider carries the obligations. Low End would change category only if it shipped its own model, for example a built-in chatbot. Then it would have to tell users they are talking to an AI (Article 50), an obligation that applies to free and open-source software too.
