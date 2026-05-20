# Last Rites

A roguelike deck-building card game built in Godot 4.6. Dark fantasy aesthetic — gothic, pixel art inspired, morally complex.

---

## Game Flow

```
Start Screen → Character Select → Battlefield (combat)
```

- **Start Screen** (`gui/start_screen/`) — New Game, Continue (hidden until a run exists), Settings, Quit
- **Character Select** (`gui/character_select/`) — animated character sprites, click to reveal info card and Begin Run
- **Battlefield** (`gui/battlefield.tscn`) — full combat loop with hand, energy, enemies, end turn

Scene transitions use a fade-to-black handled by the `SceneTransition` autoload (`gui/scene_transition/`).

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
│   ├── enemy.gd                   # Enemy — HP, block, statuses, AI, phase transitions, tier scaling
│   ├── enemy_data.gd              # EnemyData resource — identity, stats, tier, action pool, phases
│   ├── enemy_action.gd            # EnemyAction resource — one action in an AI pool
│   ├── enemy_phase.gd             # EnemyPhase resource — alternate action pool at HP threshold
│   ├── action_weight_modifier.gd  # ActionWeightModifier — conditional weight bonuses for WEIGHTED AI
│   ├── enemy.tscn                 # Enemy scene — health bar, intent display, block display, sprite
│   ├── data/
│   │   ├── deathbloom.tres        # Elite
│   │   ├── grave_rat.tres         # Minion
│   │   ├── restless_skeleton.tres # Minion (summonable)
│   │   ├── bone_sergeant.tres     # Commander
│   │   ├── plague_priest.tres     # Elite (1 phase)
│   │   └── gravewarden.tres       # Boss (2 phases)
│   ├── sprites/                   # Enemy sprite sheet PNGs
│   └── frames/
│       ├── bone_sergeant_frames.tres   # SpriteFrames resource for bone sergeant
│       ├── grave_rat_frames.tres       # SpriteFrames resource for grave rat
│       ├── gravewarden_frames.tres     # SpriteFrames resource for gravewarden
│       └── gravewarden_visual.tscn    # CharacterVisual scene for gravewarden
├── gui/
│   ├── start_screen/
│   │   ├── start_screen.tscn      # Start screen — title, New Game, Continue, Settings, Quit
│   │   └── start_screen.gd        # StartScreen — save check for Continue, settings overlay
│   ├── character_select/
│   │   ├── character_select.tscn  # Character select — animated sprites, info card, Begin Run
│   │   └── character_select.gd    # CharacterSelect — loads characters, SubViewport animations, scene swap
│   ├── character_menu/
│   │   ├── character_menu.tscn    # Tabbed character menu overlay (used during combat)
│   │   ├── character_menu.gd      # CharacterMenu — tab routing, save/quit signals
│   │   └── tabs/
│   │       ├── stats_menu.tscn / stats_tab.gd      # Character name, class, stat labels
│   │       ├── gear_menu.tscn / gear_tab.gd        # Gear slot buttons, info panel on hover
│   │       ├── save_menu.tscn / save_tab.gd        # Exit to menu / quit buttons
│   │       └── settings_menu.tscn / settings_tab.gd  # Audio sliders, fullscreen toggle
│   ├── scene_transition/
│   │   ├── scene_transition.tscn  # Fade overlay (registered as SceneTransition autoload)
│   │   └── scene_transition.gd    # transition_to(path) — fade out, swap scene, fade in
│   ├── battlefield.tscn           # Battlefield scene — full combat layout
│   ├── battlefield.gd             # Battlefield — combat wiring, targeting, deck viewer, HUD
│   ├── combat_result.tscn         # Victory/defeat overlay sub-scene
│   ├── combat_result.gd           # CombatResult — animated panel with win/loss colours
│   ├── toast.tscn                 # Floating notification sub-scene
│   ├── toast.gd                   # Toast — show_message() with rise-and-fade animation
│   └── deck_viewer.gd             # DeckViewer — overlay panel for viewing card piles
├── player/
│   ├── player_data.gd             # PlayerData resource — character identity, stats, gear slots, starter deck
│   ├── character_visual.tscn      # Base character scene — AnimatedSprite2D state machine
│   ├── character_visual.gd        # CharacterVisual — idle/attacking/hit/damaged/dead state machine
│   └── characters/
│       ├── cleric.tres            # Cleric PlayerData (CON 2, FAITH 3, 75 HP)
│       ├── cleric_visual.tscn     # Cleric visual scene — sprite sheet + animations
│       └── cleric.png             # Cleric sprite sheet (1500×810, 5×3 frames, 300×270 each)
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
- **Tier:** `MINION`, `COMMANDER`, `ELITE`, `BOSS` — drives automatic sprite scaling on the battlefield
- **Stats:** `max_health`, `base_attack`, `base_block`
- **AI pattern:** `SEQUENTIAL` (cycles pool in order) or `WEIGHTED` (picks by effective weight)
- **Action pool:** Array of `EnemyAction` resources — Attack, Block, Apply Status, Buff Self/Allies, Special
- **Phases:** optional `EnemyPhase` resources — when HP drops to or below `hp_threshold`, the phase's action pool replaces the default one

**Tier-based scaling** is automatic — no manual `visual_scale` needed:

| Tier | Scale |
|---|---|
| BOSS | 1.1× |
| ELITE / COMMANDER | 0.55× |
| MINION | 0.4× |

Override by setting `visual_scale` on the `EnemyData` resource if a specific enemy needs a custom size.

The `SPECIAL` action type fires a `special_action_triggered(param)` signal that `Battlefield`
resolves via `SUMMON_LOOKUP` (e.g. `"summon_skeleton"` spawns a restless skeleton).

**Sprite sheets** live in `enemy/sprites/` as PNGs. `SpriteFrames` resources live in `enemy/frames/`.
All sheets use 300×270px per frame.

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

To add a new character: create a `PlayerData` .tres, create a `*_visual.tscn` (instancing
`character_visual.tscn`), then add the resource path to `CHARACTER_RESOURCE_PATHS` and the class →
scene mapping to `CHARACTER_VISUAL_SCENES` in `character_select.gd`.

---

### Save System

`SaveManager` is registered as an autoload. It reads and writes `user://save.tres` automatically on
load and provides helpers for managing character and run saves.

| Method | Description |
|---|---|
| `get_or_create_character_save(character_id)` | Returns the CharacterSaveData for this character, creating it if needed |
| `end_run(character_id)` | Clears the active run on a character's save and persists |
| `save()` | Writes the current save state to disk |

The `character_id` is the path to the character's `PlayerData` .tres file
(e.g. `"res://player/characters/cleric.tres"`).

All characters share one save file. Per-character persistent data (gear, unlocked cards) lives in
`CharacterSaveData`. The active run snapshot (health, floor, deck) lives in `RunSaveData`.
The **Continue** button on the start screen is hidden until `SaveData.character_saves` is non-empty.

---

### Scene Transitions

`SceneTransition` is an autoload (`gui/scene_transition/scene_transition.tscn`). Call
`SceneTransition.transition_to("res://path/to/scene.tscn")` to fade out, swap the scene, and fade
back in. Await the call if you need to know when the transition finishes.

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

## What's Not Implemented Yet

- Audio buses (Music and SFX) — needed for settings sliders to function
- Status effect visuals on enemy cards
- Enemy AI context conditions (PLAYER_HP_BELOW_THRESHOLD etc.)
- CharacterMenu wired into battlefield pause flow
- Continue loading actual save state (currently goes to character select same as New Game)
- Run structure (map, rooms, rest sites, encounters)
- Store and event systems
- In-game compendium
- Enemy and character sprite sheets (waiting on art)
