# RPG — Dark Fantasy

A 2D dark fantasy RPG built in Godot 4.6, inspired by Eastern European folklore (Transylvania, Bram Stoker's Dracula).

---

## Project Structure

```
rpg/
├── assets/
│   └── icons/
│       └── icon_sword.svg
├── characters/
│   ├── portraits/
│   │   └── portrait_placeholder.svg
│   ├── stats/
│   │   ├── character_stats_data.gd
│   │   └── character_stats.gd
│   └── level/
│       ├── level_system.gd
│       ├── level_up_screen.gd
│       └── level_up_screen.tscn
└── color_palette.html
```

---

## Character System

### CharacterStatsData

A `Resource` that stores all serializable data for a character. Create one `.tres` file per character.

**Inspector fields:**

| Group | Field | Description |
|---|---|---|
| Identity | `character_name` | Display name |
| Identity | `character_class` | Class title (e.g. "Knight", "Witch") |
| Identity | `portrait` | Texture2D — shown in the level up screen |
| Combat | `strength` | Physical power (1–99) |
| Combat | `dexterity` | Speed and precision (1–99) |
| Combat | `vigor` | Endurance and HP (1–99) |
| Magic & Influence | `faith` | Divine / holy magic (1–99) |
| Magic & Influence | `intelligence` | Arcane magic (1–99) |
| Magic & Influence | `charisma` | Persuasion and influence (1–99) |

**Creating a character resource:**
1. In the Godot FileSystem panel, right-click your desired folder
2. New Resource → `CharacterStatsData`
3. Save as e.g. `player_stats.tres`
4. Fill in the fields in the Inspector

---

### CharacterStats

A `Node` that provides runtime stat logic. Attach as a child of any character node.

**Setup:**
1. Add a `CharacterStats` node to your character scene
2. Assign a `CharacterStatsData` resource to the `Base Stats` property in the Inspector

**Derived stats (read-only, computed from base stats):**

| Property | Formula |
|---|---|
| `max_hp` | `50 + vigor * 10` |
| `physical_attack` | `strength * 2 + dexterity / 2` |
| `magic_attack` | `intelligence * 2 + faith / 2` |
| `evasion` | `clamp(dexterity / 2, 0, 75)` |
| `persuasion_bonus` | `charisma - 10` |

**Key methods:**
```gdscript
stats.take_damage(amount: int)
stats.heal(amount: int)
stats.restore_full_hp()
stats.is_alive() -> bool
```

**Signals:**
```gdscript
stat_changed(stat_name: String, old_value: int, new_value: int)
health_changed(current_hp: int, max_hp: int)
died
```

---

### LevelSystem

A `Node` that tracks XP, current level, and unspent skill points. Attach as a sibling to `CharacterStats`.

**Setup:**
```
Character (Node2D or similar)
├── CharacterStats   ← assign character_stats_data.tres here
└── LevelSystem
```

**Inspector properties:**

| Property | Default | Description |
|---|---|---|
| `skill_points_per_level` | 3 | Points awarded per level up |
| `xp_base` | 100.0 | XP curve base constant |
| `xp_exponent` | 1.5 | XP curve exponent |

XP required formula: `floor(xp_base * level ^ xp_exponent)`

Sample thresholds: L1→2: 100 · L5→6: 1118 · L10→11: 3162

**Key methods:**
```gdscript
level_system.add_xp(amount: int)
level_system.xp_required() -> int
level_system.has_unspent_points() -> bool
```

**Signals:**
```gdscript
leveled_up(new_level: int, points_gained: int)
xp_changed(current_xp: int, xp_required: int)
```

---

## Level Up Screen

A `CanvasLayer` scene that presents the stat allocation UI when a character levels up.

### Showing the screen

```gdscript
func _on_level_system_leveled_up(_level: int, _points: int) -> void:
    var screen = preload("res://characters/level/level_up_screen.tscn").instantiate()
    add_child(screen)
    screen.open($CharacterStats, $LevelSystem)
    screen.confirmed.connect(screen.queue_free)
    screen.cancelled.connect(screen.queue_free)
```

### What the player sees

```
┌─────────────────────────────────────┐
│  [portrait]  Character Name         │
│              ───────────────        │
│              Knight                 │
│              level up               │
├─────────────────────────────────────┤
│  Level                    4         │
│  Points Available         3         │
├─────────────────────────────────────┤
│ [ Attribute Points ]                │
│                                     │
│  Strength     10  ⚔  < 10 >        │
│  Dexterity    10  ⚔  < 10 >        │
│  Vigor        10  ⚔  < 10 >        │
│  Faith        10  ⚔  < 10 >        │
│  Intelligence 10  ⚔  < 10 >        │
│  Charisma     10  ⚔  < 10 >        │
├─────────────────────────────────────┤
│           [Cancel]  [Confirm]       │
└─────────────────────────────────────┘
```

- Pending allocations are shown as `current ⚔ new` — nothing commits until **Confirm**
- Increased stats are highlighted; **Cancel** resets all pending changes

### Preview in editor

The scene is visible in the Godot scene editor without running. To preview with populated stat rows and buttons, tick **Preview** in the `LevelUpScreen` Inspector and press **F6**.

### Adding future tabs

Open `level_up_screen.gd` and find `_build_tabs()`. Uncomment or add new tab builder calls there:

```gdscript
func _build_tabs(tabs: TabContainer) -> void:
    tabs.add_child(_build_attributes_tab())
    # tabs.add_child(_build_skills_tab())
    # tabs.add_child(_build_class_tab())
```

---

## Color Palette — Blood & Parchment

Open `color_palette.html` in a browser for a full visual reference with swatches and a UI mock-up.

| Name | Hex | Usage |
|---|---|---|
| Void | `#0D0B0A` | Scene backgrounds |
| Crypt Stone | `#1C1714` | UI panels |
| Worn Stone | `#2A211C` | Hover states, separators |
| Aged Parchment | `#E8D5B0` | Primary text |
| Faded Ink | `#9A8878` | Secondary / muted text |
| Dried Blood | `#8B1A1A` | Health, danger |
| Tarnished Gold | `#C4922A` | Buttons, interactive elements |
| Nightshade | `#4A1A5C` | Magic, faith |
| Moonstone | `#B8C5D6` | Cold, ethereal |
| Pale Gold | `#D4AF5A` | Stat increased |
| Coagulated | `#8B3030` | Stat decreased, damage |
| Grave Moss | `#4A6248` | Healing, nature |

A Godot `Theme` resource applying this palette is a planned next step.
