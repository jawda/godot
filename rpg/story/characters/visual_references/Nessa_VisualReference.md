# Nessa — Visual Reference Sheet

## Overview

Nessa should read as someone who has made herself small on purpose. Not weak — deliberately contained. Every element of her appearance is about taking up less space and being harder to pin down. She is striking in a way she would prefer not to be. The mismatched layers she wears should look intentional in the way that things look intentional when someone has good instincts and zero resources.

---

## Portrait (64x64px)

### Face & Head
- **Age:** Early twenties
- **Build:** Small, sharp-featured. Pointed chin, high narrow cheekbones, a face with strong geometry that would look severe if her eyes were less alive.
- **Hair:** Short, dark, simply cut — the kind of cut done with a knife and no mirror, grown out slightly unevenly. Practical. She does not think about it.
- **Eyes:** Very dark brown, almost black. Large relative to her face. They move constantly — she is always aware of the whole room, not just what she is looking at. Slightly shadowed beneath from irregular sleep.
- **Skin:** Cool medium tone, slightly pale from three weeks of indoor living and poor sleep. No marks or scars on the face — she is careful.
- **Expression:** Still. Watchful. Not hostile — assessing. There is a quality of held breath to her default expression, like she is in the middle of deciding something.

### Clothing (portrait crop — chest and up)
- A dark layered look: a close-fitting base layer under a larger outer shirt, collar of something else visible beneath that. All dark, all slightly different — brown-black, grey-black, true black. Salvaged from different houses, worn together with accidental coherence.
- A thin cord around her neck — not the Hollow Sun, something else. A small object that doesn't catch the light. She will not explain it.
- No ornamentation. Nothing that catches the eye or makes noise.

### Portrait Colour Palette
| Element | Hex | Notes |
|---|---|---|
| Skin (base) | `#B8956A` | Cool medium tone |
| Skin highlight | `#C8A87A` | Cheekbones, nose |
| Skin shadow | `#7A5838` | Under jaw, eye sockets — pronounced |
| Eyes | `#1C1410` | Very dark brown, near black |
| Eye whites | `#C8C0A8` | Slightly cool, slightly tired |
| Under-eye shadow | `#6A4830` | Irregular sleep |
| Hair | `#1A1410` | Near black, cool undertone |
| Outer shirt | `#1A1C1A` | Near black with slight grey-green |
| Outer shirt shadow | `#0E0F0E` | Deep shadow |
| Mid layer | `#2A2820` | Slightly warmer dark |
| Base layer collar | `#1C1A1C` | Slightly cooler dark |
| Cord | `#3A3028` | Thin dark line at neck |
| Cord object | `#2A2010` | Small, does not catch light |

---

## Overworld Sprite (16x32px per frame)

### Silhouette & Proportions
- Small and narrow — the shortest of the romance characters. This should be readable in the sprite.
- The layered clothing adds slight visual bulk to the torso without changing the overall slim impression.
- Moves low — slightly crouched posture by habit, always ready to change direction. Not skulking, just compact.
- Hood exists on the outer shirt but is usually down. Up in the Abandoned Quarter at night.

### Key Sprite Details (at 16x32 scale)
- Short hair means the head silhouette is clean — no extra pixels above the skull.
- The layered collar creates a slight dark-on-dark texture at the neck.
- She is the only character who has a distinct crouch/stealth frame used in the Abandoned Quarter.
- Hands often at her sides rather than swinging — she moves without telegraphing.

### Sprite Colour Palette (reduced for pixel art)
| Element | Hex | Notes |
|---|---|---|
| Skin | `#B8956A` | Face and hands |
| Skin shadow | `#7A5838` | Side of face, deep shadows |
| Hair | `#1A1410` | Near black |
| Eyes | `#1C1410` | 1px dots, barely distinct from hair |
| Outer layer | `#1A1C1A` | Main body |
| Outer shadow | `#0E0F0E` | Deep fold darks |
| Mid layer | `#2A2820` | Visible at collar and hem |
| Hood (when up) | `#1A1C1A` | Same as outer layer |
| Boots | `#2A2010` | Dark, worn, flat-soled |

---

## Sprite Sheet Layout

### Frame Size
- **16x32px** per frame
- **Sheet:** 4 frames across × 5 rows (64x160px total — includes stealth row)

### Animation Rows
| Row | Direction | Frames | Notes |
|---|---|---|---|
| 0 | Walk Down | 4 | Minimal movement, quiet step |
| 1 | Walk Left | 4 | |
| 2 | Walk Right | 4 | |
| 3 | Walk Up | 4 | Hood up in Abandoned Quarter context |
| 4 | Stealth/Crouch | 4 | Lower profile, slower movement |

### Walk Cycle Notes
- The quietest walk animation of any character — minimal arm swing, small steps
- No bounce. Her movement should feel like she is trying to leave no impression on the ground.
- The stealth row is used when the player is in the Abandoned Quarter at night — matches her natural movement style

---

## Mood Reference Words
Contained · Watchful · Precise · Careful · Sharp · Unexpectedly dry humour · Stillness that costs something

---

## Files to Create
| File | Dimensions | Location |
|---|---|---|
| `nessa_portrait.png` | 64x64px | `res://characters/portraits/` |
| `nessa_sprite.png` | 64x160px | `res://characters/sprites/` |
