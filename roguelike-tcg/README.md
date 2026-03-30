# RoguelikeTCG

A roguelike deck-building card game built in Godot 4.6.

---

## Project Structure

```
roguelike-tcg/
├── cards/
│   ├── card.tscn            # Card scene (160x240px UI control)
│   ├── card.gd              # Card visuals — reads from a CardData resource
│   ├── card_data.gd         # CardData resource class — defines all card properties
│   ├── card_effect.gd       # CardEffect resource class — defines a single card effect (damage, block, draw, etc.)
│   ├── card_palette.gd      # CardPalette resource class — defines rarity color themes
│   ├── data/
│   │   ├── void_strike.tres # Example card resource
│   │   ├── strike.tres      # Starter attack card
│   │   └── defend.tres      # Starter defense card
│   └── palettes/
│       ├── common.tres
│       ├── uncommon.tres
│       ├── rare.tres
│       ├── mythic.tres
│       └── special.tres
├── decks/
│   ├── deck_data.gd         # DeckData resource class — defines deck name, class, and card list
│   ├── deck.gd              # Deck runtime class — draw/discard piles, add/remove cards
│   └── data/
│       └── starter_deck.tres # Default 10-card starter deck (5× Strike, 5× Defend)
├── gui/
│   ├── game.tscn            # Main game scene (in progress)
│   └── battlefield.tscn     # Battlefield layout (in progress)
├── documents/
│   └── creating-a-card.md   # Step-by-step guide for creating and configuring cards
├── player/
│   ├── player_data.gd       # PlayerData resource — character identity, base stats, starting gear
│   ├── character_visual.tscn # Character scene — AnimatedSprite2D + state machine
│   ├── character_visual.gd  # CharacterVisual — state machine (idle/attack/hit/dead) + signals
│   └── gear/
│       ├── gear_data.gd     # GearData resource — item name, slot, rarity, effects
│       └── gear_effect.gd   # GearEffect resource — a single passive or triggered gear effect
├── save/
│   ├── save_manager.gd      # SaveManager autoload — file I/O, run management (register in Project Settings)
│   ├── save_data.gd         # SaveData resource — top-level save file, holds all character saves
│   ├── character_save_data.gd # CharacterSaveData — per-character persistent data (gear, active run)
│   └── run_save_data.gd     # RunSaveData — current run snapshot (health, floor, gold, deck)
├── gui/
│   └── character_menu/
│       ├── character_menu.tscn  # Character menu scene — tabbed overlay
│       ├── character_menu.gd    # CharacterMenu — opens/closes menu, routes save/quit signals
│       └── tabs/
│           ├── stats_tab.gd     # StatsTab — populates stat labels from PlayerData
│           ├── gear_tab.gd      # GearTab — gear slot buttons, info panel on selection
│           ├── save_tab.gd      # SaveTab — exit to menu / quit buttons with save trigger
│           └── settings_tab.gd  # SettingsTab — audio sliders, fullscreen toggle, persists to settings.cfg
├── hand.gd                  # Hand class — manages card layout and fan arc in hand
├── test_game_interface.gd   # Test UI controller — wires up draw/discard/reset buttons
├── main.tscn                # Active test scene — hand layout and card draw/discard testing
└── project.godot
```

---

## Documents

Detailed guides are in the `documents/` folder:

| Document | Description |
|---|---|
| [Creating a Card](documents/creating-a-card.md) | Step-by-step guide — card properties, effects, tokens, BBCode, and adding new card types |

---

## Hand System

The `Hand` class (`hand.gd`) manages a collection of card instances and positions them
in a curved fan arc. It extends `ColorRect` so its bounds define the usable hand area.

### Layout

Cards are distributed across the hand width and arced vertically and rotationally using
two Godot `Curve` resources sampled per card position.

| Export | Type | Description |
|---|---|---|
| `hand_curve` | Curve | Controls the vertical arc — samples 0→1 across cards to set Y offset |
| `rotation_curve` | Curve | Controls card tilt — samples 0→1 across cards to set rotation |
| `max_rotation_degrees` | int | Maximum rotation applied at the curve extremes |
| `x_sep` | int | Gap in pixels between cards — negative values overlap cards |
| `y_min` | int | Minimum Y offset (flat/center cards) |
| `y_max` | int | Maximum Y offset (peak of the arc) |

If the total card width exceeds the hand container's width, cards automatically overlap
to fit within the bounds.

### Methods

| Method | Description |
|---|---|
| `draw()` | Instantiates a new card, adds it to the hand, and recalculates layout |
| `discard()` | Removes the last card from the hand and recalculates layout |

> **Note:** `draw()` currently instantiates a default card. It will be updated to draw
> from a deck of `CardData` resources once the deck system is implemented.

### Test Scene

`main.tscn` contains a working test of the hand system with three buttons wired up via
`test_game_interface.gd`:

- **Draw Card** — calls `hand.draw()`
- **Discard Card** — calls `hand.discard()`
- **Reset** — reloads the scene

---

## Deck System

Decks are data-driven. Each deck is a `DeckData` resource saved as a `.tres` file in `decks/data/`. At runtime a `Deck` object is created from the data and manages the draw and discard piles.

### DeckData resource (`decks/deck_data.gd`)

| Property | Type | Description |
|---|---|---|
| `deck_name` | String | Display name for the deck |
| `description` | String (multiline) | Flavour text / notes |
| `class_id` | String | Ties the deck to a player class — leave empty for the universal starter deck |
| `starter_cards` | Array[CardData] | The cards in the deck — drag `.tres` card resources into this array |

**Deck size rules:** minimum 10 cards, maximum 40 cards. These limits are enforced by `Deck.add_card()` and `Deck.remove_card()`.

### Deck runtime class (`decks/deck.gd`)

Instantiate with `Deck.new()`, then call `load_from_data(deck_data)` to populate and shuffle it.

| Method | Returns | Description |
|---|---|---|
| `load_from_data(deck_data)` | void | Loads cards from a DeckData resource and shuffles the draw pile |
| `shuffle()` | void | Randomly shuffles the current draw pile |
| `draw_card()` | CardData? | Pops and returns the top card; returns null if the draw pile is empty |
| `discard_card(card_data)` | void | Moves a card to the discard pile |
| `reshuffle_discard_into_draw()` | void | Moves all discarded cards back into the draw pile and shuffles |
| `add_card(card_data)` | bool | Adds a card to the deck (store/event use only); returns false if at MAX_SIZE |
| `remove_card(card_data)` | bool | Removes a card from the deck (store/event use only); returns false if at MIN_SIZE or card not found |
| `draw_pile_count()` | int | Number of cards remaining in the draw pile |
| `discard_pile_count()` | int | Number of cards in the discard pile |
| `total_count()` | int | Total cards in the deck (draw + discard) |

### Starter deck

`decks/data/starter_deck.tres` is the default deck given to every class until class-specific decks are defined. It contains 5× Strike (Attack, cost 1 — deal 6 damage) and 5× Defend (Defense, cost 1 — gain 5 Block).

### Wiring a deck to the Hand

```gdscript
var deck: Deck = Deck.new()
deck.load_from_data(preload("res://decks/data/starter_deck.tres"))
hand.set_deck(deck)
```

The Hand's `draw()` method will then pull cards from the deck rather than spawning blank cards. Discarded cards are automatically sent to the deck's discard pile.

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

## Adding a New Rarity Tier

**Step 1 — Add the enum value**

Open `cards/card_data.gd` and append to the `Rarity` enum:

```gdscript
enum Rarity { COMMON, UNCOMMON, RARE, MYTHIC, SPECIAL, PROMO }
```

**Step 2 — Add the display label**

Open `cards/card.gd` and append to `RARITY_LABELS` in the same position:

```gdscript
const RARITY_LABELS: Array[String] = ["Common", "Uncommon", "Rare", "✦ Mythic ✦", "✦ Special ✦", "Promo"]
```

**Step 3 — Create a palette resource**

Right-click `cards/palettes/` in the FileSystem → **New Resource** → search for `CardPalette`.
The easiest starting point is duplicating an existing `.tres` and editing the colors.
See [Palette Property Reference](#palette-property-reference) below.

**Step 4 — Register the palette**

In `cards/card.gd`, append the new palette to the `PALETTES` array. Order must match
the `Rarity` enum (index 0 = COMMON, etc.):

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

**Step 5 — Enable pulse (optional)**

If the new tier should have a pulsing glow, update the threshold in `_apply_palette()`
inside `cards/card.gd`:

```gdscript
if data.effective_rarity >= CardData.Rarity.MYTHIC:
```

---

## Editing an Existing Palette

Select any `.tres` file in `cards/palettes/` from the FileSystem panel. The Inspector
shows all properties grouped by section with color pickers. Changes apply to every card
using that palette immediately.

Alternatively, open the `.tres` file in a text editor and adjust the `Color(r, g, b, a)`
values directly. Colors use normalized floats — `1.0` is max, `0.0` is none.

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
| `name_border` | Color | Name banner border |
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
| `rarity_strip_x0` | int | Left offset of the rarity strip within the description box — decrease to widen |
| `rarity_strip_x1` | int | Right offset of the rarity strip within the description box — increase to widen |
