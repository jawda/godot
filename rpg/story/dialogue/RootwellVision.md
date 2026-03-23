# The Rootwell Vision

## Overview

After the player has rested at the Tallow Inn two or three times, they are pulled from sleep in the middle of the night by something they cannot immediately name. A light. Not fire — something colder, older. Coming from the direction of Rootwell Square.

They do not choose to go. They are already walking before they have fully decided.

This sequence is the first direct communication between the player and the entity. It is not a conversation. It is closer to a memory that does not belong entirely to the player — a fragment of something vast leaking through the thinnest point in the ground.

It should leave the player unsettled in the way that a dream does when you wake and cannot decide whether it was frightening or beautiful and it turns out to be both.

---

## Trigger Conditions

- Player has rested at the Tallow Inn **2–3 times** (exact number TBD — enough to feel settled in Duskholm, not so many that it feels like a grind)
- Time of day: deep night — the inn is quiet, no ambient NPC sounds
- The sequence triggers on the rest screen fade-out, interrupting what should be a normal sleep

---

## Scene Script

### Beat 1 — The Waking

*The player's room. Dark. The candle on the bedside table has burned down to nothing.*

*The player's vision resolves slowly from black — the way waking from deep sleep actually works, not all at once.*

*The room is as it was. Normal. Except —*

*Through the small window, across the rooftops, there is a light in the square. Not lantern-warm. Blue-white. Faint and steady, like something seen underwater.*

*No dialogue. No prompt. The player regains movement control.*

*If they look away from the window and try to return to bed: the light intensifies slightly. Not aggressively — patiently. It has time.*

---

### Beat 2 — The Walk

*The player exits the inn. Duskholm at deep night — emptier than usual, even by this town's standards. The ambient creature sounds from the Mirewald are absent. Everything is very still.*

*The light from Rootwell Square is visible between buildings. It does not flicker. It does not move.*

*The player walks toward it. NPC collision is disabled for this sequence — if any NPCs are in their night positions they are asleep or absent.*

*As the player approaches the square the light brightens gradually. Not blinding — the way a room brightens when you open a door to a lit hallway.*

*The Rootwell is glowing. The light comes from inside it, from below, from very far below. The stone of the well's rim is warm to the touch.*

---

### Beat 3 — The Flashback

*The player reaches the well. A prompt: look down.*

*When they do, the vision begins.*

*The screen does not cut to black. It breathes — a slow fade into the first image, like fog clearing.*

---

**FRAGMENT ONE — Warmth**

*An interior. Stone walls, low ceiling, firelight. The feeling of being small — a child's perspective, though no child is visible.*

*The fire is burning normally. Someone is nearby — a presence more than a person, warmth at the edge of the frame. A hand on a table. A cup.*

*It is peaceful. It is domestic. It is somewhere the player has been before.*

*But the fire is too orange. Too bright. Something about the quality of the light is slightly wrong.*

*The fragment dissolves before the player can identify the room.*

---

**FRAGMENT TWO — The Symbol**

*Stone. Ancient, weathered stone — not Duskholm stone, older. Carved into the surface of it: the Hollow Sun.*

*But this carving is not the Covenant's version. It is rougher. More worn. It predates anything Serafin has built — it predates the Church, it predates the names. It is simply a circle with a line descending, and it means something that has no current word for it.*

*A hand traces the carving. Not the player's hand — someone else's. The fingers are adult, calloused, unhurried.*

*The image holds for a moment longer than the others. The entity is trying to communicate something specific here. What, exactly, is not yet clear.*

---

**FRAGMENT THREE — The Voice**

*No image. Just sound — or not quite sound. The feeling of a word being said, without the word itself arriving. The way a name sounds when spoken in another room and you hear the shape of it but not the syllables.*

*The player's character does not hear this with their ears. They hear it somewhere else. Somewhere older.*

*It is their name. Or something that functions as their name. Or something that has always been their name and they did not know until now.*

*A single pulse of warmth. Not threatening. Recognising.*

---

**FRAGMENT FOUR — The Fire**

*Outside. Night. Orange light — too much of it, from the wrong direction.*

*Something is burning.*

*The player cannot see what. The angle is wrong — they are moving away, or being moved, the ground uneven underfoot, the smoke rising in a column that blots out the stars.*

*Behind them: the sound of the bells ringing. Low to high. Backwards.*

*The bells of Ashveil.*

*The fragment cuts before the player turns around.*

---

**FRAGMENT FIVE — The Root**

*Darkness. Then, slowly — a root. A single massive root, running through black earth, lit from within by the same blue-white light as the Rootwell. It is vast. It runs in all directions. It runs beneath everything.*

*The player's perspective pulls back slowly — far enough to see that the root is not alone, that it is one of thousands, that they form a web beneath the surface of the whole world.*

*In the centre of the web: something. Not a form. Not a face. A presence so large that its awareness of the player — tiny, on the surface, far above — is like being noticed by the ocean.*

*It does not reach toward them. It does not have to.*

*It has known they were coming for a very long time.*

---

### Beat 4 — Return

*The player's vision clears. They are at the Rootwell. Kneeling — they don't remember kneeling.*

*The light in the well is gone. The stone is cold again.*

*The square is empty and dark. The Mirewald treeline is visible to the north, the same as always.*

*The player regains full control. No prompt. No explanation. The journal does not update. There is nothing to do but go back to bed or start the day.*

*Dawn is still hours away.*

---

## Design Notes

### What Is Deliberately Ambiguous

The flashback is designed so that on first viewing, the player does not know:

- Whether Fragment One is a memory of Ashveil before the fire, or somewhere else entirely
- Whose hand traces the carving in Fragment Two — a parent, the entity, Serafin, someone unnamed
- Whether Fragment Three is the entity communicating or a dream echo of something the player once heard
- Whether Fragment Four is the burning of Ashveil or something older — the framing is intentional
- Whether the presence in Fragment Five is benevolent, neutral, or something that does not map onto either category

On replay or in late-game context, each fragment has a more specific meaning that the player can retroactively assign. This is intentional.

### What Is Not Ambiguous

The player was at Ashveil. The bells rang backwards. Something beneath the ground has been aware of them, specifically, for a long time. Whatever it knows about why they survived, it has not said yet.

### Repetition

The vision does not repeat exactly. If the player rests again before the vision's significance is addressed in the main quest, they may experience a shorter, quieter version — Fragment Five only, the root and the presence, briefer. As if the entity has said what it needed to say and is now simply... present.

### Visual Direction
- No text overlays during fragments — no subtitles, no journal prompts, nothing
- Transitions between fragments: slow dissolves, not cuts
- Colour palette shifts during the vision: the Blood & Parchment palette desaturates toward blue-white and deep black. Only the fire fragments retain warm colour.
- Sound: ambient tone only — low, continuous, subsonic. The bells in Fragment Four are the loudest thing in the sequence and they should feel wrong in a specific way: too loud for the distance, too clear for a dream
- Duration: the full sequence should feel like it takes approximately 90 seconds. Long enough to be absorbed, short enough to feel like it ended before you were ready

---

## Notes / To Do

- Decide the exact rest count trigger (2 or 3)
- Define the shorter repeat version of the vision (Fragment Five only)
- Decide whether the vision has any mechanical consequence — journal entry, stat change, or purely narrative
- The backwards bells in Fragment Four should be the same sound used in the intro story text — audio consistency
- Late game: in Ending Three, the player returns to the Rootwell voluntarily. What they see then should echo this sequence but resolved — the fragments answered, the presence no longer distant
