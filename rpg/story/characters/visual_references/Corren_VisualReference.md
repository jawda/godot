# Corren — Visual Reference Sheet

## Overview

Corren should read as someone who is strong because her work made her that way, not because she tries to be. Nothing about her is decorative. Everything she wears and carries has a purpose. She is attractive in the way that competence and self-possession are attractive — it isn't what she is going for and that is part of it.

---

## Portrait (64x64px)

### Face & Head
- **Age:** Mid-twenties
- **Build:** Angular face, strong jaw, high cheekbones. Not delicate — defined.
- **Hair:** Natural texture, kept in a utilitarian wrap or low knot while working. A few loose strands that escaped. Never styled, always functional.
- **Eyes:** Dark brown, direct. She looks at things straight on. No downward glance, no softness in the default expression.
- **Skin:** Deep warm brown. A faint burn scar along the left jaw from an early forge accident she never talks about. Small marks on her neck and collarbones from metal sparks.
- **Expression:** Neutral assessment. Not unfriendly — evaluating. The face of someone deciding whether you are worth their time.

### Clothing (portrait crop — chest and up)
- Heavy leather apron over a dark linen work shirt, collar open. The apron has burn marks and is stiff with use.
- No jewelry. No ornamentation of any kind.
- The leather wrap in her hair is the same dark brown as the apron — practical accident rather than coordination.
- Shoulders and upper arms show the lean muscle of forge work — visible even through the shirt.

### Portrait Colour Palette
| Element | Hex | Notes |
|---|---|---|
| Skin (base) | `#7A4A2A` | Deep warm brown |
| Skin highlight | `#9A6040` | Cheekbones, forehead, nose bridge |
| Skin shadow | `#4A2A14` | Under jaw, eye sockets, neck |
| Eyes | `#2A1A0A` | Very dark brown, near black |
| Eye whites | `#D4C4A8` | Slightly warm, not pure white |
| Hair | `#1A1008` | Near black with warm undertone |
| Hair wrap | `#5A3018` | Dark leather brown |
| Shirt | `#2A2018` | Very dark linen, warm black |
| Apron | `#5A3A1A` | Worn leather, mid brown |
| Apron shadow | `#3A2010` | Deep fold shadows |
| Burn scar (jaw) | `#8A5030` | Slightly raised, paler than skin |
| Spark marks | `#5A3020` | Small scattered marks |

---

## Overworld Sprite (16x32px per frame)

### Silhouette & Proportions
- Average height, compact. The silhouette should read as solid and grounded — feet planted, no bounce in the walk.
- Broad through the shoulders relative to body width — the visual weight is in the upper body.
- Wears the apron over clothes at all times when at the smithy. If encountered elsewhere, no apron — just the dark work shirt and trousers.
- Does not carry a visible weapon by default. Her hands are empty. She does not need to signal threat.

### Key Sprite Details (at 16x32 scale)
- Hair wrap creates a slight horizontal line across the upper head — distinguishing silhouette detail.
- Apron creates a slightly lighter vertical panel down the front of the body — separates her visually from background.
- Arms hang slightly away from the body — the muscle means her arms don't rest flush at her sides.
- Work trousers tucked into mid-calf boots, dark and worn.

### Sprite Colour Palette (reduced for pixel art)
| Element | Hex | Notes |
|---|---|---|
| Skin | `#7A4A2A` | Face and hands |
| Skin shadow | `#4A2A14` | Side of face, knuckles |
| Hair | `#1A1008` | Dark near-black |
| Hair wrap | `#5A3018` | Slight contrast from hair |
| Eyes | `#2A1A0A` | 1-2px dots |
| Shirt | `#2A2018` | Main body (no apron scenes) |
| Apron base | `#5A3A1A` | Front panel |
| Apron shadow | `#3A2010` | Edges and folds |
| Trousers | `#1C1810` | Dark, slightly cooler than shirt |
| Boots | `#3A2818` | Mid-brown, worn |

---

## Sprite Sheet Layout

### Frame Size
- **16x32px** per frame
- **Sheet:** 4 frames across × 4 rows (64x128px total)

### Animation Rows
| Row | Direction | Frames | Notes |
|---|---|---|---|
| 0 | Walk Down | 4 | Slight shoulder movement, grounded step |
| 1 | Walk Left | 4 | Mirror for right walk |
| 2 | Walk Right | 4 | |
| 3 | Walk Up | 4 | Hair wrap visible from behind |

### Walk Cycle Notes
- Low centre of gravity — no bounce, deliberate steps
- Arms swing slightly but not excessively
- At the smithy she has a separate idle animation: small hammer movement (optional, implement later)

---

## Mood Reference Words
Grounded · Direct · Self-sufficient · Quietly warm · Competent · Unhurried · Not performing anything

---

## Files to Create
| File | Dimensions | Location |
|---|---|---|
| `corren_portrait.png` | 64x64px | `res://characters/portraits/` |
| `corren_sprite.png` | 64x128px | `res://characters/sprites/` |
