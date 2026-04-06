# Roguelike TCG

A roguelike deck-building card game built in Godot 4.6. Dark fantasy aesthetic — gothic, pixel art inspired, morally complex.

---

## Project Structure

```
roguelike-tcg/
├── cards/
│   ├── card.tscn                  # Card scene (160×240px UI control)
│   ├── card.gd                    # Card visuals — reads from a CardData resource
│   ├── card_data.gd               # CardData resource — defines all card properties
│   ├── card_effect.gd             # CardEffect resource — one effect per card (damage, block, draw, etc.)
│   ├── card_palette.gd            # CardPalette resource — per-rarity color themes
│   ├── data/
│   │   ├── neutral/               # Neutral cards (available to all classes)
│   │   └── cleric/                # Cleric class card pool (21 draft cards + 3 starters)
│   └── palettes/
│       ├── common.tres
│       ├── uncommon.tres
│       ├── rare.tres
│       ├── mythic.tres
│       └── special.tres
├── combat/
│   ├── combat_manager.gd          # CombatManager — full turn cycle (player/enemy), effect resolution
│   └── combat_player.gd           # CombatPlayer — runtime player state (HP, block, energy, statuses)
├── decks/
│   ├── deck_data.gd               # DeckData resource — deck name, class id, card list
│   ├── deck.gd                    # Deck runtime class — draw/discard piles, reshuffle
│   └── data/
│       ├── starter_deck.tres      # Neutral starter deck
│       └── cleric_starter_deck.tres  # Cleric starter deck (Mace Strike × 4, Ward × 4, Prayer × 2)
├── enemy/
│   ├── enemy.gd                   # Enemy — HP, block, statuses, AI, phase transitions
│   ├── enemy_data.gd              # EnemyData resource — identity, stats, action pool, phases
│   ├── enemy_action.gd            # EnemyAction resource — one action in an AI pool
│   ├── enemy_phase.gd             # EnemyPhase resource — alternate action pool at HP threshold
│   ├── action_weight_modifier.gd  # ActionWeightModifier — conditional weight bonuses for WEIGHTED AI
│   ├── enemy.tscn                 # Enemy scene — health bar, intent display, block display, sprite
│   └── data/
│       ├── shambling_corpse.tres  # Minion
│       ├── grave_rat.tres         # Minion
│       ├── restless_skeleton.tres # Minion (summonable)
│       ├── bone_sergeant.tres     # Commander
│       ├── plague_priest.tres     # Elite (1 phase)
│       └── gravewarden.tres       # Boss (2 phases)
├── gui/
│   ├── battlefield.tscn           # Battlefield scene — full combat layout
│   ├── battlefield.gd             # Battlefield — combat wiring, targeting, pile buttons, HUD
│   ├── deck_viewer.gd             # DeckViewer — overlay panel for viewing card piles
│   └── character_menu/
│       ├── character_menu.tscn    # Tabbed character menu overlay
│       ├── character_menu.gd      # CharacterMenu — tab routing, save/quit signals
│       └── tabs/
│           ├── stats_tab.gd       # StatsTab — character name, class, stat labels
│           ├── gear_tab.gd        # GearTab — gear slot buttons, info panel on hover
│           ├── save_tab.gd        # SaveTab — exit to menu / quit buttons
│           └── settings_tab.gd    # SettingsTab — audio sliders, fullscreen toggle
├── player/
│   ├── player_data.gd             # PlayerData resource — character identity, stats, gear slots, starter deck
│   ├── character_visual.tscn      # Character scene — AnimatedSprite2D + state machine
│   ├── character_visual.gd        # CharacterVisual — idle/attacking/hit/damaged/dead state machine
│   └── characters/
│       └── cleric.tres            # Cleric PlayerData (CON 2, FAITH 3, 75 HP)
│   └── gear/
│       ├── gear_data.gd           # GearData resource — item name, slot, rarity, effects
│       └── gear_effect.gd         # GearEffect resource — one passive or triggered gear effect
├── save/
│   ├── save_manager.gd            # SaveManager autoload — file I/O, run management
│   ├── save_data.gd               # SaveData resource — top-level save file, holds all character saves
│   ├── character_save_data.gd     # CharacterSaveData — per-character persistent data (gear, active run)
│   └── run_save_data.gd           # RunSaveData — current run snapshot (health, floor, gold, deck)
├── documents/
│   ├── creating-a-card.md         # Guide — card properties, effects, tokens, BBCode
│   ├── creating-a-character.md    # Guide — PlayerData, stats, starter deck, gear, visual scene
│   ├── characters/
│   │   └── cleric.html            # Cleric character design sheet (dev reference)
│   └── enemies/
│       └── *.html                 # Enemy design sheets (dev reference)
├── hand.gd                        # Hand — curved fan layout, drag-to-cast, hover/focus
├── test_game_interface.gd         # TestGameInterface — wires draw/discard/reset buttons (dev scene)
└── project.godot
```

---

## Documents

Guides are in the `documents/` folder:

| Document | Description |
|---|---|
| [Creating a Card](documents/creating-a-card.md) | Card properties, effects, tokens, BBCode reference, adding card types |
| [Creating a Character](documents/creating-a-character.md) | PlayerData resource, stats, starter deck, gear slots, visual scene |

---

## Core Systems

### Cards

Cards are data-driven. Each card is a `CardData` resource (`.tres` file). The `card.tscn` scene is a
reusable visual template that reads from a `CardData` resource assigned to it. Every card has a type,
cost, rarity, and an array of `CardEffect` resources that define what it does when played.

See [Creating a Card](documents/creating-a-card.md) for a full guide.

**Card types:** `ATTACK`, `QUIRK`, `POWER`, `CURSE`, `STATUS`, `DEFENSE`
**Rarity tiers:** `COMMON` → `UNCOMMON` → `RARE` → `MYTHIC` → `SPECIAL`
**Card classes:** `NEUTRAL` (all classes), `CLERIC`

Upgrading a card bumps its effective rarity by one tier (capped at SPECIAL) and applies any
`upgraded_value` overrides on its effects.

---

### Deck System

Each deck is a `DeckData` resource (`.tres` file in `decks/data/`). At runtime a `Deck` object
manages the draw and discard piles.

**Deck size rules:** minimum 10 cards, maximum 40 cards.

Key `Deck` methods:

| Method | Description |
|---|---|
| `load_from_data(deck_data)` | Loads from a DeckData resource and shuffles the draw pile |
| `draw_card()` | Returns the top card; auto-reshuffles discard into draw when pile is empty |
| `discard_card(card_data)` | Sends a card to the discard pile |
| `add_card(card_data)` | Adds a card to the deck (store/event use); returns false if at MAX_SIZE |
| `remove_card(card_data)` | Removes a card from the deck; returns false if at MIN_SIZE or not found |
| `get_all_cards()` | Returns a copy of the full card list (draw + discard) |
| `get_draw_pile()` | Returns a copy of the current draw pile |
| `get_discard_pile()` | Returns a copy of the current discard pile |

---

### Hand System

The `Hand` class manages card instances in a curved fan arc. Cards are positioned using two sampled
`Curve` resources and support mouse + controller focus, staggered deal animation, and drag-to-cast.

**Drag-to-cast:** drag a card upward 80px above its resting position — it glows gold. On release,
`card_drag_play_requested(card_data, release_pos)` fires. The `Battlefield` resolves the release
position against living enemy rects and plays the card directly, or falls back to targeting mode.

Non-targeting cards (Block, Prayer) cast immediately on release. Attack cards that miss an enemy
enter targeting mode, where the player clicks an enemy to finish the cast.

---

### Combat System

`CombatManager` drives the full turn cycle:

1. **Player turn** — draw 5 cards, play cards, end turn
2. **Enemy turn** — each enemy resolves its action in sequence (0.6s delay), then back to player turn
3. **Victory** when all enemies are dead; **defeat** when the player reaches 0 HP

**Energy:** 3 per turn by default. Each card costs energy equal to `card_cost`.

**Block:** clears at the start of each player turn (Slay the Spire style). Each point of Dexterity
adds 1 bonus block per `gain_block` call.

**Status effects implemented:** `burn`, `bleed`, `void`, `weak`, `vulnerable`, `double_heal`,
`free_next_card`. Statuses tick at turn start; DoT fires before new cards are drawn.

**Faith scaling:** each point of Faith adds 10% to all HP restored from HEAL effects. Formula:
`actual_heal = base × (1.0 + faith × 0.1)`.

**Holy damage:** deals double damage to enemies tagged `"undead"`.

---

### Enemy System

Each enemy is an `EnemyData` resource with:
- **Stats:** `max_health`, `base_attack`, `base_block`
- **AI pattern:** `SEQUENTIAL` (cycles pool in order) or `WEIGHTED` (picks by effective weight)
- **Action pool:** Array of `EnemyAction` resources — Attack, Block, Apply Status, Buff Self/Allies, Special
- **Phases:** optional `EnemyPhase` resources — when HP drops to or below `hp_threshold`, the phase's action pool replaces the default one

The `SPECIAL` action type fires a `special_action_triggered(param)` signal that `Battlefield`
resolves via `SUMMON_LOOKUP` (e.g. `"summon_skeleton"` spawns a restless skeleton).

---

### Characters

Each playable character is a `PlayerData` resource with:
- Character name, class string, description
- Base stats: STR, DEX, CON, INT, FAITH
- `base_max_health` — actual max HP = `base_max_health + (constitution × 10)`
- `starter_deck` reference (a `DeckData` resource)
- 6 gear slots: helmet, necklace, ring_left, ring_right, armor, weapon

See [Creating a Character](documents/creating-a-character.md) for a full guide.

**Available characters:** Cleric (`player/characters/cleric.tres`)

---

### Save System

`SaveManager` is registered as an autoload (Project Settings → Autoload). It reads and writes
`user://save.tres` automatically on load and provides helpers for managing character and run saves.

| Method | Description |
|---|---|
| `get_or_create_character_save(character_id)` | Returns the CharacterSaveData for this character, creating it if needed |
| `end_run(character_id)` | Clears the active run on a character's save and persists |
| `save()` | Writes the current save state to disk |

The `character_id` is the path to the character's `PlayerData` .tres file
(e.g. `"res://player/characters/cleric.tres"`).

---

### Rarity Tiers

| Tier | Description |
|---|---|
| Common | Muted slate-gray |
| Uncommon | Verdant emerald |
| Rare | Electric sapphire |
| Mythic | Molten amber/gold — pulsing glow |
| Special | Void crimson/magenta — intense pulsing glow |

---

### Character Menu

`gui/character_menu/character_menu.tscn` is a tabbed overlay opened over the battlefield. Contains:

- **Stats tab** — character name, class, all stat values, current HP, gold
- **Gear tab** — six gear slots with hover-to-preview info panel
- **Settings tab** — master/music/SFX audio sliders, fullscreen toggle, exit to menu, quit

Wiring: call `character_menu.open(player_data, character_save_data)` to populate and show it.
Connect `character_menu.closed` to resume the game.

---

## Active Test Scene

`gui/game.tscn` — loads the Cleric starter deck, deals 5 cards, and has Draw/Discard/Reset buttons.
Used for testing hand layout and card visuals in isolation.

---

## What's Not Implemented Yet

- Status effect visuals on enemies
- Combat system integration with Faith/Intelligence formulas
- Run structure (map, rooms, rest sites)
- Character select screen and start menu
- In-game compendium
- Store and event systems
- Enemy and character sprite sheets (waiting on art)
