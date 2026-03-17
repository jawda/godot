# Serafin Voss — Visual Reference Sheet

## Overview

Serafin reads as a man of former authority who has shed his institution but not his bearing. He should look like a priest who stopped believing in the Church but never stopped believing in *something*. Gaunt, controlled, unsettling in his stillness.

---

## Portrait (64x64px)

### Face & Head
- **Age:** Late 50s
- **Build:** Lean, angular face — high cheekbones, hollow cheeks, sharp jaw
- **Hair:** Bald on top, close-cropped grey on the sides and back. No beard — clean shaven, which makes his face feel severe and exposed
- **Eyes:** Deep-set, pale grey or washed-out blue. The kind of eyes that don't blink enough. Slightly sunken with dark circles beneath — not from fatigue, just the look of someone who has seen too much and processed all of it
- **Skin:** Pale, almost ashen. Faint lines around the mouth from years of controlled expression. A thin scar along the left jawline from an old inquisitor's wound he never explains
- **Expression:** Neutral tending toward calm. Not cold — *certain*. He looks like a man who has already had every argument you're about to make and found it wanting

### Clothing (portrait crop — chest and up)
- Black vestments, formerly Church robes, stripped of all gold trim and insignia. The fabric is good quality but worn — he has been in the field a long time
- A dark leather cord around his neck disappearing below frame — implies the Hollow Sun pendant hangs there
- Collar is slightly open, deliberately casual in a way that feels calculated

### Portrait Colour Palette
| Element | Hex | Notes |
|---|---|---|
| Skin | `#C9A882` | Warm parchment base |
| Skin shadow | `#9A7355` | Cheeks, under eyes, jaw |
| Skin deep shadow | `#6B4E35` | Eye sockets, under chin |
| Hair (grey) | `#8A8A8A` | Sides and back |
| Hair highlight | `#ADADAD` | Top of grey band |
| Eyes | `#9AADB8` | Pale washed blue-grey |
| Eye shadow | `#2A3A40` | Beneath brow |
| Robes (base) | `#1C1714` | Near-black, warm tint |
| Robes shadow | `#0D0B0A` | Deep fold shadows |
| Robes highlight | `#2E2520` | Subtle fabric catch-light |
| Scar | `#7A4A3A` | Left jawline, thin |

---

## Overworld Sprite (16x32px per frame)

### Silhouette & Proportions
- Tall and thin — use maximum vertical space in the 16x32 frame
- Head takes up roughly 8x8px of the top
- Narrow shoulders — not a fighter's build
- Long robes that reach near the floor — legs barely visible beneath, giving him a gliding quality when animated
- Holds his hands clasped in front of him at rest, or one hand slightly raised as if mid-gesture

### Clothing Detail (at 16x32 scale — simplified)
- Dark robe with a slightly lighter hem line at the bottom to separate from background
- A single vertical stripe of slightly lighter dark down the centre front — the ghost of where the Church insignia was removed
- Hood down — his bare head is an important part of his silhouette
- The leather cord should be a single 1px dark line visible at the neck

### Sprite Colour Palette (reduced for pixel art)
| Element | Hex | Notes |
|---|---|---|
| Skin | `#C9A882` | Face and hands |
| Skin shadow | `#9A7355` | Side of face, knuckles |
| Hair | `#8A8A8A` | Grey side band, 1-2px wide |
| Eyes | `#9AADB8` | 1-2px dots |
| Robes base | `#1C1714` | Main body |
| Robes shadow | `#0D0B0A` | Between legs, under arms |
| Robes edge | `#2E2520` | Outline catch, hem |
| Cord | `#3A2A1A` | 1px neck detail |

---

## Sprite Sheet Layout

### Frame Size
- **16x32px** per frame
- **Sheet width:** 4 frames across (64px total)
- **Sheet height:** 4 rows down (128px total)

### Animation Rows
| Row | Direction | Frames | Notes |
|---|---|---|---|
| 0 (top) | Walk Down (toward camera) | 4 | Robe sways slightly |
| 1 | Walk Left | 4 | Mirror for right |
| 2 | Walk Right | 4 | |
| 3 | Walk Up (away from camera) | 4 | Back of bald head visible |

### Walk Cycle Notes
- Serafin's walk should feel deliberate and unhurried — no bounce
- Minimal leg movement visible under robes — the robe hem shifts side to side
- His hands stay clasped, arms barely swing
- Frame 0 and frame 2 of each row are the neutral/mid poses; frames 1 and 3 are the left/right step extremes

---

## Hollow Sun Brand (detail for portrait)
- Inside left wrist — if wrist is visible in portrait, include a small `#8B5030` burn scar in the shape of a circle with a downward line
- At portrait scale this is roughly 4x4px of detail

---

## Mood Reference Words
Austere · Certain · Weathered · Controlled · Sorrowful beneath the surface · Former institutional power worn loosely · The quiet of a man who stopped needing to prove himself

---

## Files to Create
| File | Dimensions | Location |
|---|---|---|
| `serafin_portrait.png` | 64x64px | `res://characters/portraits/` |
| `serafin_sprite.png` | 64x128px | `res://characters/sprites/` |
