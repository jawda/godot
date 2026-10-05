# Dialog System

Ported from the `aarpg` tutorial project, but with the tedious node-tree authoring
replaced by [Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager)
text files. The polished presentation — typewriter text, animated portrait, voice
blips, NEXT/END indicator, choice buttons — is kept as a **custom balloon**; Dialogue
Manager only supplies the conversation content and branching.

## How the pieces fit

| Piece | Where | Role |
| --- | --- | --- |
| `DialogSystem` (autoload) | `gui/dialog/dialog_system.tscn` + `.gd` | The on-screen balloon. Walks a `.dialogue` resource line by line and renders it. The only thing the game calls. |
| `DialogPortrait` | `gui/dialog/dialog_portrait.gd` | Mouth/blink animation + voice blips, driven by the typewriter. |
| `SpeakerLibrary` (autoload) | `gui/dialog/speaker_library.gd` | Maps a speaker name → `SpeakerResource` (portrait + voice pitch). |
| `SpeakerResource` | `gui/dialog/speaker_resource.gd` | One per speaker, stored in `gui/dialog/speakers/`. |
| `DialogueManager` (autoload) | `addons/dialogue_manager/` | Parses `.dialogue` files and handles branching/conditions/mutations. |
| Conversations | `dialog/scripts/*.dialogue` | The actual writing. |

## Play a conversation from code

```gdscript
DialogSystem.start(load("res://dialog/scripts/intro.dialogue"), "start")
```

`start` is the title (cue) to begin from. The balloon pauses the game, plays the
conversation, then unpauses and emits `DialogSystem.finished`.

## Write a new conversation

Add a file under `dialog/scripts/`, e.g. `shopkeeper.dialogue`:

```
~ start
Greta: Welcome to the forge. Looking for anything in particular?
- Show me your wares
	Greta: Take your time.
	=> END
- Just browsing
	Greta: Suit yourself.
	=> END
```

- `~ name` defines a title you can start from. A file can have several.
- `Speaker: text` — the part before the colon is the speaker name.
- Lines with **no** `Speaker:` show with no name/portrait (good for narration).
- `- option` lines are choices; the **tab-indented** block under each runs when chosen.
- `=> END` ends the conversation; `=> some_title` jumps elsewhere.

Single- vs multi-character is automatic: just change (or omit) the name before the
colon. Indentation under choices must be **tabs**.

## Add a new speaker

1. Use a `*_Face_64x64.png` portrait sheet — a 4x2 grid of 8 frames (top row
   eyes-open, bottom row blinking; columns are mouth states). The character
   `Face_64x64` sheets under `assets/characters/` are already this layout.
2. Duplicate one of the `.tres` files in `gui/dialog/speakers/`, set its
   `speaker_name`, `portrait`, and `audio_pitch`.

That's it — `SpeakerLibrary` scans the folder on load, so no registration is needed.
Any name used in a `.dialogue` file that has no matching `SpeakerResource` falls back
to `portrait_placeholder.png` and a neutral pitch.

## Trying it now

`dialog/demo.tscn` is a temporary harness (no player/world needed yet): run it and
press `1` for the two-character branching scene or `2` for the single-character scene.
Once a player and interaction system exist, those will call `DialogSystem.start()`
and this demo scene can be deleted.

## Later (not built yet)

- **Quests:** Dialogue Manager `if`/`do` conditions and mutations can call a future
  `QuestManager` autoload straight from a `.dialogue` file — no balloon changes needed.
- **Cutscenes:** drive `DialogueManager.get_next_dialogue_line()` directly (without
  waiting on player input) for auto-advancing sequences.
- **World triggers:** an interaction component (e.g. a walk-up `Area2D`) that calls
  `DialogSystem.start()` — the aarpg version of this was intentionally not ported yet.
