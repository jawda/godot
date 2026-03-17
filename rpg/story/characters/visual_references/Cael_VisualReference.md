# Cael — Visual Reference Sheet

## Overview

Cael should read as someone who is in slightly the wrong clothes for where he is and has not noticed. He is not dishevelled — he is just oriented toward function and his function is thinking, not presenting. There is an openness to his face that feels genuine rather than performed. He looks like someone it would be easy to talk to.

---

## Portrait (64x64px)

### Face & Head
- **Age:** Mid-twenties
- **Build:** Slim, slightly narrow-faced. Soft jaw relative to the other male characters. The face of someone who grew up indoors with books.
- **Hair:** Dark brown, medium length, slightly wavy and imperfectly kept. Falls across the forehead when he hasn't pushed it back recently. Always looks like it dried without much attention.
- **Eyes:** Warm hazel — brown leaning green. Wide and attentive. The kind of eyes that are always slightly focused on something slightly past you, thinking.
- **Skin:** Medium warm tone, indoor-pale but not sallow. Ink stains on his right hand and often one cheek. Small crease at the corner of his eyes when he smiles, which is often.
- **Expression:** Open and slightly preoccupied. His default face is mid-thought. When he focuses on you fully it is noticeable because it's a distinct shift.

### Clothing (portrait crop — chest and up)
- A travelling coat in muted olive-brown, slightly too large, with many pockets. Collar turned up. Well-made but not expensive — the kind of thing bought for durability on long journeys.
- A light scarf looped loosely at the neck — more habit than warmth.
- The strap of a leather satchel visible at one shoulder.
- An ink smudge on the left side of his jaw that he has not noticed.

### Portrait Colour Palette
| Element | Hex | Notes |
|---|---|---|
| Skin (base) | `#C4956A` | Medium warm tone |
| Skin highlight | `#D4A87A` | Forehead, nose, cheekbones |
| Skin shadow | `#8A6040` | Under jaw, eye sockets |
| Eyes | `#7A6030` | Warm hazel brown |
| Eye detail | `#4A5020` | Green undertone fleck |
| Hair | `#3A2010` | Dark warm brown |
| Hair highlight | `#5A3820` | Catch-light on top |
| Coat | `#5A5030` | Muted olive-brown |
| Coat shadow | `#3A3018` | Deep fold shadows |
| Coat highlight | `#7A7040` | Shoulder catch-light |
| Scarf | `#8A7050` | Slightly lighter than coat |
| Ink stain | `#1A1830` | Blue-black ink on skin |
| Satchel strap | `#6A4A28` | Worn tan leather |

---

## Overworld Sprite (16x32px per frame)

### Silhouette & Proportions
- Slim, slightly taller than average. Carries his height lightly — not quite straight posture, a habitual slight lean as if permanently about to look at something.
- The coat is the dominant visual element — it has enough volume to read clearly at small scale.
- Satchel strap across the body creates a diagonal detail that helps break up the silhouette.
- Scarf loop at neck is a small but consistent detail.

### Key Sprite Details (at 16x32 scale)
- Hair falls slightly forward — 1-2px overhang on the forehead distinguishes him from other characters.
- Coat hem falls to mid-thigh — gives him a slightly longer visual proportion than shorter-coated characters.
- At idle near his table in the Glasshouse: notebook in hand, pen moving (optional animation).

### Sprite Colour Palette (reduced for pixel art)
| Element | Hex | Notes |
|---|---|---|
| Skin | `#C4956A` | Face and hands |
| Skin shadow | `#8A6040` | Side of face |
| Hair | `#3A2010` | Dark warm brown |
| Eyes | `#7A6030` | 1-2px warm hazel |
| Coat base | `#5A5030` | Main body |
| Coat shadow | `#3A3018` | Under arms, folds |
| Coat highlight | `#7A7040` | Shoulder edge |
| Scarf | `#8A7050` | Neck detail |
| Satchel | `#6A4A28` | Diagonal strap line |
| Trousers | `#3A3828` | Dark, slightly cooler |
| Boots | `#2A2018` | Dark, simple |

---

## Sprite Sheet Layout

### Frame Size
- **16x32px** per frame
- **Sheet:** 4 frames across × 4 rows (64x128px total)

### Animation Rows
| Row | Direction | Frames | Notes |
|---|---|---|---|
| 0 | Walk Down | 4 | Coat moves, satchel bounces slightly |
| 1 | Walk Left | 4 | Hair flicks with movement |
| 2 | Walk Right | 4 | |
| 3 | Walk Up | 4 | Coat back visible, satchel strap diagonal |

### Walk Cycle Notes
- Slightly uneven gait — his attention is often not entirely on where he is going
- The coat hem should shift with movement to give the walk visual life
- A slight head-tilt in the down-facing idle frame — his default thinking pose

---

## Mood Reference Words
Curious · Open · Slightly distracted · Genuinely warm · Quick · Slightly fumbling · Thinks faster than he speaks and sometimes the opposite

---

## Files to Create
| File | Dimensions | Location |
|---|---|---|
| `cael_portrait.png` | 64x64px | `res://characters/portraits/` |
| `cael_sprite.png` | 64x128px | `res://characters/sprites/` |
