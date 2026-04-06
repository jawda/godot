# Creating a Character

Characters are data-driven. Each character is a `PlayerData` resource saved as a `.tres` file in
`player/characters/`. The game reads from it at run start to build the character's combat stats,
populate the character menu, and initialize the save system.

---

## Step 1 — Create a new PlayerData resource

In the Godot FileSystem panel, right-click the `player/characters/` folder and choose
**New Resource**. Search for `PlayerData` and confirm. Save the file with the character's name,
e.g. `warrior.tres`.

Alternatively, duplicate `player/characters/cleric.tres` and rename it — then update every field.

---

## Step 2 — Fill in the character identity

Select the new `.tres` file. In the Inspector, expand the **Character** group.

| Property | Type | Description |
|---|---|---|
| `character_name` | String | The character's display name — shown in the Stats tab of the character menu |
| `character_class` | String | Class label string, e.g. `"Cleric"`, `"Warrior"` — shown under the name in the Stats tab |
| `character_description` | String (multiline) | Flavour text for the character — used in future character select screen |
| `starter_deck` | DeckData | Drag in the character's starter `DeckData` resource — see [Step 4](#step-4--set-the-starter-deck) |

---

## Step 3 — Set the base stats

Expand the **Base Stats** group. These are the character's starting values before any gear or
combat modifiers. The runtime adds gear bonuses on top.

| Stat | Effect |
|---|---|
| `strength` | Each point adds 1 to damage dealt by all ATTACK effects |
| `dexterity` | Each point adds 1 bonus block per `gain_block` call (stacks with base value) |
| `constitution` | Each point adds 10 to maximum HP. Formula: `max_hp = base_max_health + (constitution × 10)` |
| `intelligence` | Effect TBD — reserved for spell and card synergy scaling |
| `faith` | Each point adds 10% to all HP restored from HEAL effects. Formula: `actual_heal = base × (1.0 + faith × 0.1)` |
| `base_crit_chance` | Base critical hit chance as a percentage — gear can increase this at runtime |

> **Tip:** Lean into a single pillar. The Cleric has high FAITH (3) and moderate CON (2) — that
> gives her a meaningful heal multiplier and extra HP without spreading points across five stats.

---

## Step 4 — Set the starter deck

The `starter_deck` field takes a `DeckData` resource. This deck is loaded at the start of every run.

**Option A — use an existing deck**

Drag `decks/data/cleric_starter_deck.tres` (or `starter_deck.tres`) into the `starter_deck` slot.

**Option B — create a new starter deck**

1. Right-click `decks/data/` → **New Resource** → search for `DeckData` → save as e.g. `warrior_starter_deck.tres`.
2. Select the new resource. Fill in:
   | Property | Description |
   |---|---|
   | `deck_name` | Display name for the deck |
   | `class_id` | Optional — a string matching the class (e.g. `"warrior"`). Leave empty for a universal deck |
   | `starter_cards` | Drag `.tres` card resources into this array |
3. Starter decks must contain at least 10 cards (the deck minimum). 10 is a good starting point.
4. Drag the new deck into the `starter_deck` slot on the `PlayerData` resource.

See [Creating a Card](creating-a-card.md) if you need to make cards for the starter deck first.

---

## Step 5 — Set base max health

Expand the **Health** group.

| Property | Type | Description |
|---|---|---|
| `base_max_health` | int | Starting HP before constitution scaling. Actual max HP at combat start = `base_max_health + (constitution × 10)` |

> **Example:** The Cleric has `base_max_health = 75` and `constitution = 2`, giving her `75 + 20 = 95` actual max HP in combat.

---

## Step 6 — Set starting gear (optional)

Expand the **Starting Gear** group. Most characters start with no gear — leave these slots empty.

If the character should begin a run with a specific item already equipped, drag the relevant
`GearData` resource into the appropriate slot.

| Slot | Field | Description |
|---|---|---|
| Helmet | `helmet` | Head armor slot |
| Necklace | `necklace` | Accessory slot |
| Ring (Left) | `ring_left` | Ring slot |
| Ring (Right) | `ring_right` | Ring slot |
| Armor | `armor` | Body armor slot |
| Weapon | `weapon` | Weapon slot |

---

## Step 7 — Create the character visual scene (optional)

If you have sprite art ready, create a `CharacterVisual` scene for the character.

1. Instance `player/character_visual.tscn` as a base.
2. Select the `$Sprite` node and assign the character's `SpriteFrames` resource.
3. The state machine expects these animation names: `"idle"`, `"attack"`, `"hit"`, `"damaged"`, `"death"`.
   Create them in the SpriteFrames editor.
4. Save the scene as e.g. `player/characters/warrior_visual.tscn`.

If no sprite art is ready, the scene will show a placeholder — this is expected and does not
break the combat scene. Art can be added later without changing any other files.

---

## Step 8 — Register with the save system

The save system identifies characters by the path to their `PlayerData` resource. Use this path
as the `character_id` when calling `SaveManager.get_or_create_character_save()`.

```gdscript
const CLERIC_ID: String = "res://player/characters/cleric.tres"

var character_save: CharacterSaveData = SaveManager.get_or_create_character_save(CLERIC_ID)
```

The save system creates a `CharacterSaveData` on first use and persists it across sessions. It
stores the character's gear (which persists between runs) and the active run snapshot (health,
floor, gold, deck list).

---

## Worked example — Cleric

The Cleric is implemented in `player/characters/cleric.tres`:

| Field | Value |
|---|---|
| `character_name` | `"The Cleric"` |
| `character_class` | `"Cleric"` |
| `strength` | `0` |
| `dexterity` | `0` |
| `constitution` | `2` |
| `intelligence` | `0` |
| `faith` | `3` |
| `base_max_health` | `75` |
| `starter_deck` | `cleric_starter_deck.tres` |

**Derived values at combat start:**
- Max HP: `75 + (2 × 10) = 95`
- Heal multiplier: `1.0 + (3 × 0.1) = 1.3` — all heals restore 30% more

**Design pillars:**
- **Holy damage** — Sacred Strike and similar cards deal HOLY damage type, which doubles against undead enemies
- **Block stacking** — Bulwark and Martyr's Guard build high block totals
- **Life economy** — Lay on Hands, Sacred Mending, Blood Tithe scale on HP restored this combat

---

## Card Class Field

If the character should have exclusive cards that don't appear in other classes' draft pools,
set `card_class` on their `CardData` resources to the matching enum value.

Currently defined class values (in `cards/card_data.gd`):

| Enum value | Cards available to |
|---|---|
| `NEUTRAL` | All classes |
| `CLERIC` | Cleric only |

To add a new class value, open `cards/card_data.gd` and append to `CardClass`:

```gdscript
enum CardClass { NEUTRAL, CLERIC, WARRIOR }
```

Then set `card_class = CardClass.WARRIOR` on any cards exclusive to the Warrior.

---

## Stat Reference

| Stat | Combat effect | Where applied |
|---|---|---|
| `strength` | +1 damage per point to all ATTACK effects | `combat_manager.gd` — `_deal_player_damage_to_enemy()` |
| `dexterity` | +1 block per point to all BLOCK effects | `combat_player.gd` — `gain_block()` |
| `constitution` | +10 max HP per point | `combat_player.gd` — `setup()` |
| `intelligence` | Effect TBD | — |
| `faith` | +10% to all heals per point | `combat_player.gd` — `heal()` |
