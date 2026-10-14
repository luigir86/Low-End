# Low End for assistants and language models

Low End is built "LLM first": everything a player can do on screen is also an **action** with a name, JSON arguments and a JSON answer, so an assistant can tune, start a drone or read the tuner just like a finger can.

The actions live in [`lib/actions/app_actions.dart`](../lib/actions/app_actions.dart). The screens use the same controllers, so the two can never drift apart. The full catalog, in the tool format used by MCP and by the Claude, Gemini and OpenAI APIs, is in [`llm-actions.json`](llm-actions.json) (a test keeps it in sync with the code).

## Actions

| Action | What it does |
|---|---|
| `get_state` | Section on screen, tuner (status, tuning, last note, cents off, in tune), drone (playing, note, fifth, octave, volume), reference A |
| `open_section` | Shows `tuner`, `drone` or `metronome` |
| `tuner_start` | Opens the tuner and listens (optionally with a `tuning`) |
| `tuner_stop` | Stops listening |
| `set_tuning` | `orchestral`, `solo`, `cExtension`, `fiveLowB`, `fiveHighC`, `fourStrings`, `fiveStrings`, `sixStrings`, `dropD` or `chromatic` |
| `drone_play` | Plays the drone, applying `note` (A, Bb2, Sol1…), `octave`, `add_fifth`, `add_octave`, `volume` |
| `drone_stop` | Stops the drone |
| `drone_set` | Changes the drone settings without starting or stopping it |
| `set_reference_pitch` | A4 = 440, 441, 442 or 443 Hz |

Every answer is `{"ok": true, "state": {...}}` or `{"ok": false, "error": "..."}`, with an error message an assistant can read and fix.

## Calling them today: action links

On Android and iPhone the app opens links of the form

```
lowend://action/<action>?<argument>=<value>&...
```

for example `lowend://action/drone_play?note=D&octave=2&add_fifth=true` or `lowend://action/tuner_start?tuning=solo`. Any assistant, shortcut or automation app that can open a link can use them (on Android, for example, Tasker, a home-screen shortcut, or `adb shell am start -d "lowend://action/drone_stop"` to try it).

Links can only do what the buttons do. The microphone still listens only while the tuner is on screen, so `tuner_start` brings the tuner to the front.

## Next steps

1. **Android App Functions** (Android 16 and later): publish the same actions to the system so Gemini and other assistants can call them and read the answer, through a small Kotlin layer that forwards to the Dart actions.
2. **iPhone App Intents**: the same for Siri and Shortcuts.
3. **MCP server** (optional, for desktop assistants such as Claude): only if someone needs it, since it would need a network connection, which the app avoids today.

## AI Act

Exposing actions to an assistant does not make Low End an AI system: the assistant (Gemini, Siri, Claude…) is the AI system and its provider carries the obligations. Low End would change category only if it shipped its own model, for example a built-in chatbot. Then it would have to tell users they are talking to an AI (Article 50), an obligation that applies to free and open-source software too.
