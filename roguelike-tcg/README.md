# RoguelikeTCG

A roguelike deck-building card game built in Godot 4.6.

---

## Project Structure

```
roguelike-tcg/
├── cards/
│   ├── card.tscn            # Card scene (160x240px UI control)
│   ├── card.gd              # Card logic and visual application
│   ├── card_palette.gd      # CardPalette resource class definition
│   └── palettes/
│       ├── common.tres
│       ├── uncommon.tres
│       ├── rare.tres
│       ├── mythic.tres
│       └── special.tres
├── main.tscn                # Test scene, displays a single card centered on screen
└── project.godot
```

---

## Card Properties (Inspector)

When a `card.tscn` instance is selected in the editor, the Inspector exposes two groups:

### Card Data
| Property | Type | Description |
|---|---|---|
| `card_name` | String | Display name shown on the name banner |
| `card_cost` | int | Energy cost shown in the top-left badge |
| `card_type` | CardType | Dropdown — controls the type label below the name banner |
| `card_description` | String (multiline) | Supports BBCode (bold, color, etc.) |

### Rarity
| Property | Type | Description |
|---|---|---|
| `base_rarity` | Rarity | The card's starting rarity tier |
| `upgraded` | bool | If true, effective rarity = base_rarity + 1 (capped at Special) |

The card updates live in the editor viewport when any property changes.

---

## Rarity Tiers

Each tier has a unique color palette. Higher tiers add visual effects.

| Tier | Palette | Effects |
|---|---|---|
| Common | Muted slate-gray | — |
| Uncommon | Verdant emerald | — |
| Rare | Electric sapphire | Stronger border glow |
| Mythic | Molten amber/gold | Thicker border, pulsing glow, gold name with amber outline |
| Special | Void crimson/magenta | Thickest border, intense pulse, white name with magenta outline |

Mythic and Special cards have a looping glow animation that pulses the card's shadow in and out.

---

## Adding a New Card Type

Card types are defined in two places in `cards/card.gd`. Both must be updated together.

**Step 1 — Add the enum value**

Open `cards/card.gd` and find the `CardType` enum near the top of the file:

```gdscript
enum CardType { ATTACK, SKILL, POWER, CURSE, STATUS }
```

Append your new type:

```gdscript
enum CardType { ATTACK, SKILL, POWER, CURSE, STATUS, STANCE }
```

**Step 2 — Add the display label**

Directly below the enum, find `CARD_TYPE_LABELS`:

```gdscript
const CARD_TYPE_LABELS: Array[String] = ["Attack", "Skill", "Power", "Curse", "Status"]
```

Append the label string in the **same position** as the enum value you added:

```gdscript
const CARD_TYPE_LABELS: Array[String] = ["Attack", "Skill", "Power", "Curse", "Status", "Stance"]
```

> **Important:** The array index must match the enum value. `ATTACK = 0` maps to `"Attack"` at index 0,
> `SKILL = 1` maps to `"Skill"` at index 1, and so on. If the order gets out of sync, cards will
> display the wrong type label.

That's it. The new type will appear in the `card_type` dropdown in the Inspector immediately.

---

## Adding a New Rarity Tier

Palettes are now separate resource files, so adding a new rarity tier involves four steps across three files.

**Step 1 — Add the enum value**

Open `cards/card.gd` and append to the `Rarity` enum:

```gdscript
enum Rarity { COMMON, UNCOMMON, RARE, MYTHIC, SPECIAL, PROMO }
```

**Step 2 — Add the display label**

In the same file, append to `RARITY_LABELS` in the same position:

```gdscript
const RARITY_LABELS := ["Common", "Uncommon", "Rare", "✦ Mythic ✦", "✦ Special ✦", "Promo"]
```

**Step 3 — Create a palette resource**

Create a new file at `cards/palettes/promo.tres`. The easiest starting point is to duplicate
an existing `.tres` file and edit the colors. See the Palette Property Reference below for
what each property controls.

The file header should stay the same, only the property values change:

```
[gd_resource type="Resource" script_class="CardPalette" load_steps=2 format=3]

[ext_resource type="Script" path="res://cards/card_palette.gd" id="1"]

[resource]
script = ExtResource("1")
body_bg = Color(...)
...
```

You can also create the file from inside Godot: right-click the `palettes/` folder in the
FileSystem panel → **New Resource** → search for `CardPalette`.

**Step 4 — Register the palette**

In `cards/card.gd`, append the preloaded resource to the `PALETTES` array. Order must match
the `Rarity` enum (index 0 = COMMON, index 1 = UNCOMMON, etc.):

```gdscript
const PALETTES: Array[CardPalette] = [
    preload("res://cards/palettes/common.tres"),
    preload("res://cards/palettes/uncommon.tres"),
    preload("res://cards/palettes/rare.tres"),
    preload("res://cards/palettes/mythic.tres"),
    preload("res://cards/palettes/special.tres"),
    preload("res://cards/palettes/promo.tres"),  # new
]
```

**Step 5 — Update the pulse check (optional)**

If the new tier should have a pulsing glow, update the condition in `_apply_palette()`:

```gdscript
if effective_rarity >= Rarity.MYTHIC:
```

---

## Editing an Existing Palette

Select any `.tres` file in `cards/palettes/` from the Godot FileSystem panel. The Inspector
will show all properties grouped by section with color pickers. Changes save directly to the
file and apply to any card using that palette immediately.

Alternatively, open the `.tres` file in a text editor and adjust the `Color(r, g, b, a)` values
directly. Colors use normalized floats — `1.0` is max, `0.0` is none.

---

## Palette Property Reference

All properties are defined in `cards/card_palette.gd` and grouped by section.

### Card Body
| Property | Type | Description |
|---|---|---|
| `body_bg` | Color | Main card background |
| `border` | Color | Card border and primary accent color |
| `shadow` | Color | Glow/shadow color (include alpha for intensity) |
| `border_width` | int | Border thickness in pixels — 2 = normal, 3 = premium feel |
| `shadow_base` | int | Resting shadow size |
| `shadow_peak` | int | Peak shadow size during pulse — set equal to `shadow_base` for no pulse |

### Cost Badge
| Property | Type | Description |
|---|---|---|
| `cost_bg` | Color | Cost badge background |
| `cost_border` | Color | Cost badge border |
| `cost_text` | Color | Cost number text color |

### Art Frame
| Property | Type | Description |
|---|---|---|
| `art_border` | Color | Art frame border — typically the accent color at reduced alpha |

### Name Banner
| Property | Type | Description |
|---|---|---|
| `name_bg` | Color | Name banner background |
| `name_border` | Color | Name banner top/bottom border |
| `name_text` | Color | Card name text — use a distinct color on high rarity tiers to make it pop |
| `name_outline` | Color | Font outline on the card name — set alpha to 0 for none |
| `name_outline_size` | int | Outline thickness in pixels — 0 = none, 2–3 for premium tiers |

### Type & Description
| Property | Type | Description |
|---|---|---|
| `type_text` | Color | Type label color (the "— Attack —" line) |
| `desc_border` | Color | Description box border |
| `desc_text` | Color | Description body text color |

### Rarity Strip
| Property | Type | Description |
|---|---|---|
| `rarity_bg` | Color | Rarity strip background |
| `rarity_border` | Color | Rarity strip border |
| `rarity_text` | Color | Rarity label text color |
| `rarity_strip_x0` | int | Left offset of the rarity strip — decrease to widen |
| `rarity_strip_x1` | int | Right offset of the rarity strip — increase to widen |
