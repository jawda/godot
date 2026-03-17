# Rowan — Visual Reference Sheet

## Overview

Rowan should read as someone who is built for the outdoors and is currently sitting very still indoors and finding it difficult. He is big enough to be physically imposing and has clearly made a long-term effort not to be, which creates a specific quality — a large man who has learned softness, and you can see the effort and the result at the same time. He is trying to look like nobody. He is not quite succeeding.

---

## Portrait (64x64px)

### Face & Head
- **Age:** Early thirties
- **Build:** Strong jaw, broad face, a nose that has been broken once and set slightly imperfectly. Not classically handsome — substantial. The kind of face that looks like it has been through things and arrived somewhere that is not quite peace but is not war either.
- **Hair:** Dark brown, cut close at the sides and slightly longer on top, going noticeably grey at the temples earlier than it should. The grey is not distinguished-looking — it looks like stress wearing a hair colour.
- **Eyes:** Grey-green. Direct when he is comfortable, slightly unfocused when he is processing something difficult, which is often. A small permanent crease between his brows from years of thinking hard about things that do not resolve cleanly.
- **Skin:** Medium warm tone, weathered and tanned from years of outdoor work. A small scar at the corner of his mouth — a thin line, old and pale. He does not explain it.
- **Expression:** Carefully neutral. He has trained himself to stillness in a group setting. Alone or with someone he trusts, the face loosens considerably. The portrait should catch him in a moment of almost-relaxation — not quite guarded, not quite open.

### Clothing (portrait crop — chest and up)
- Plain dark travelling clothes — a heavy linen shirt in deep charcoal, worn open at the collar. No insignia, no Covenant markings. He has been in civilian clothes for five weeks and still does not wear them with full ease.
- A dark woollen vest over the shirt, practical rather than decorative. Slightly too warm for the Tallow Inn's fire but he keeps it on.
- Something at the collar — the cord of the Hollow Sun brand is the only Covenant thing he still carries. It is under the shirt. The cord is just visible above the collar if you look.
- The scar at his mouth is visible — fine and pale, the corner of his lip.

### Portrait Colour Palette
| Element | Hex | Notes |
|---|---|---|
| Skin (base) | `#B87848` | Medium warm, weathered |
| Skin highlight | `#C89060` | Cheekbones, nose, forehead |
| Skin shadow | `#7A4A28` | Under jaw, eye sockets |
| Eyes | `#6A7858` | Grey-green |
| Eye shadow | `#3A3028` | Under brow, deep-set |
| Hair (dark) | `#2A1C10` | Main hair, warm dark brown |
| Hair (grey) | `#888078` | Temples — cool grey |
| Hair grey highlight | `#A09888` | Catch-light on grey |
| Brow crease | `#8A5830` | Slightly deeper than skin |
| Shirt | `#2A2A28` | Deep charcoal linen |
| Shirt shadow | `#1A1A18` | Fold darks |
| Vest | `#1E1C1A` | Near black wool, warmer than shirt |
| Vest edge | `#2A2826` | Slight separation from shirt |
| Cord | `#3A2A18` | Just above collar, barely visible |
| Mouth scar | `#D4A878` | Pale, fine — lighter than skin |

---

## Overworld Sprite (16x32px per frame)

### Silhouette & Proportions
- The broadest of the romance characters — his shoulder width is visible even at 16px. This is his most immediately distinguishing silhouette feature.
- Medium-tall height. Solid through the torso.
- Despite his build he does not move heavily — he is careful and deliberate, someone who learned to move quietly as a necessity.
- The vest over shirt creates a slight layered depth in the torso.

### Key Sprite Details (at 16x32 scale)
- Shoulder width needs to be pushed to the edges of the 16px frame — this is what makes him readable as physically distinct.
- Grey temples: 1-2px of lighter grey on each side of the dark hair mass. Small detail but important for recognition.
- The cord is not visible at sprite scale — it is a portrait-only detail.
- He stands with his arms slightly crossed in idle — a closed-off posture that is also protective.

### Sprite Colour Palette (reduced for pixel art)
| Element | Hex | Notes |
|---|---|---|
| Skin | `#B87848` | Face and hands |
| Skin shadow | `#7A4A28` | Side of face, strong shadows |
| Hair (dark) | `#2A1C10` | Main hair mass |
| Hair (grey) | `#888078` | Temple pixels — 1-2px each side |
| Eyes | `#6A7858` | 1-2px grey-green |
| Shirt | `#2A2A28` | Main body |
| Shirt shadow | `#1A1A18` | Under arms, neck |
| Vest | `#1E1C1A` | Layered over shirt, subtle |
| Trousers | `#2A2820` | Dark, practical |
| Boots | `#3A2818` | Mid-dark brown, worn |

---

## Sprite Sheet Layout

### Frame Size
- **16x32px** per frame
- **Sheet:** 4 frames across × 4 rows (64x128px total)

### Animation Rows
| Row | Direction | Frames | Notes |
|---|---|---|---|
| 0 | Walk Down | 4 | Deliberate, quiet step for his size |
| 1 | Walk Left | 4 | |
| 2 | Walk Right | 4 | |
| 3 | Walk Up | 4 | Broad back and shoulders most prominent |

### Walk Cycle Notes
- His walk should feel heavier than other characters — grounded steps — but not slow
- He does not swing his arms widely. Controlled movement.
- Idle animation: arms folded or one hand resting on the table surface (Tallow Inn context)
- His up-facing walk shows the most distinctive silhouette — wide shoulders from behind

---

## Covenant Mark (detail for portrait)
- The Hollow Sun brand is on the inside of his left wrist — the same as Serafin's, as it is a Covenant initiation mark
- At portrait scale, if the wrist is visible: `#8A5030` burn scar, the same symbol, roughly 4x4px
- He keeps it covered. It is a late-game reveal if the wrist is shown — either in a scene of trust or a scene of confrontation

---

## Mood Reference Words
Substantial · Deliberate · Carrying weight · Careful stillness · Honest at cost · Built for outdoors and sitting very still indoors · The quiet of someone who has run out of certainties

---

## Files to Create
| File | Dimensions | Location |
|---|---|---|
| `rowan_portrait.png` | 64x64px | `res://characters/portraits/` |
| `rowan_sprite.png` | 64x128px | `res://characters/sprites/` |
