class_name RunSaveData
extends Resource

## Snapshot of an in-progress run. Created at run start, discarded on death or victory.
## floor_sequence_paths is stored so a resumed run can reconstruct RunState.floor_sequence
## without going back through character select.
## Gear found mid-run that the player hasn't equipped is tracked here until run end,
## at which point it is merged into CharacterSaveData.gear_stash.

# ── Health ─────────────────────────────────────────────────────────────────────

@export var current_health: int = 0:
	set(new_current_health):
		current_health = new_current_health
		emit_changed()

@export var current_max_health: int = 0:
	set(new_current_max_health):
		current_max_health = new_current_max_health
		emit_changed()

# ── Progression ────────────────────────────────────────────────────────────────

@export var current_floor: int = 1:
	set(new_current_floor):
		current_floor = new_current_floor
		emit_changed()

## The generated map for the current floor. Null between floors.
## Current room position is tracked on the map itself via floor_map.current_room_index.
@export var floor_map: FloorMapData = null:
	set(new_floor_map):
		floor_map = new_floor_map
		emit_changed()

@export var gold: int = 0:
	set(new_gold):
		gold = new_gold
		emit_changed()

# ── Level ──────────────────────────────────────────────────────────────────────

@export var level: int = 1:
	set(new_level):
		level = new_level
		emit_changed()

@export var xp: int = 0:
	set(new_xp):
		xp = new_xp
		emit_changed()

## Level-up stat choices not yet claimed. Incremented once per level gained.
@export var pending_stat_choices: int = 0:
	set(new_pending_stat_choices):
		pending_stat_choices = new_pending_stat_choices
		emit_changed()

## True when the player has earned a Mastery but has not yet claimed it at a rest site.
@export var pending_mastery: bool = false:
	set(new_pending_mastery):
		pending_mastery = new_pending_mastery
		emit_changed()

## All masteries claimed so far this run. Lost on death (levels reset on death).
@export var active_masteries: Array[MasteryData] = []:
	set(new_active_masteries):
		active_masteries = new_active_masteries
		emit_changed()

# ── Level stat bonuses ─────────────────────────────────────────────────────────
## +1 increments earned through level-up choices during this run.
## Applied on top of base PlayerData stats at the start of each combat.

@export var bonus_strength: int = 0:
	set(new_bonus_strength):
		bonus_strength = new_bonus_strength
		emit_changed()

@export var bonus_dexterity: int = 0:
	set(new_bonus_dexterity):
		bonus_dexterity = new_bonus_dexterity
		emit_changed()

@export var bonus_constitution: int = 0:
	set(new_bonus_constitution):
		bonus_constitution = new_bonus_constitution
		emit_changed()

@export var bonus_intelligence: int = 0:
	set(new_bonus_intelligence):
		bonus_intelligence = new_bonus_intelligence
		emit_changed()

@export var bonus_faith: int = 0:
	set(new_bonus_faith):
		bonus_faith = new_bonus_faith
		emit_changed()

# ── Deck ───────────────────────────────────────────────────────────────────────

## Paths to CardData .tres files representing the player's current deck.
## Changes as cards are added or removed during the run.
@export var deck_card_paths: Array[String] = []:
	set(new_deck_card_paths):
		deck_card_paths = new_deck_card_paths
		emit_changed()

## Per-copy upgrade flags, index-matched to deck_card_paths.
## true = this specific copy has been upgraded at a rest site.
@export var deck_card_upgrades: Array[bool] = []:
	set(new_deck_card_upgrades):
		deck_card_upgrades = new_deck_card_upgrades
		emit_changed()

# ── Potion belt ────────────────────────────────────────────────────────────────
## Consumables currently held (max 3 slots). Persists between floors, lost on death.
@export var consumables: Array[ConsumableData] = []:
	set(new_consumables):
		consumables = new_consumables
		emit_changed()

# ── Equipped gear ──────────────────────────────────────────────────────────────
# Copied from CharacterSaveData at run start. Changes made at rest sites, shops,
# and the blacksmith are saved here. Written back to CharacterSaveData at run end.

@export var helmet: OwnedGear:
	set(new_helmet):
		helmet = new_helmet
		emit_changed()

@export var necklace: OwnedGear:
	set(new_necklace):
		necklace = new_necklace
		emit_changed()

@export var ring_left: OwnedGear:
	set(new_ring_left):
		ring_left = new_ring_left
		emit_changed()

@export var ring_right: OwnedGear:
	set(new_ring_right):
		ring_right = new_ring_right
		emit_changed()

@export var armor: OwnedGear:
	set(new_armor):
		armor = new_armor
		emit_changed()

@export var boots: OwnedGear:
	set(new_boots):
		boots = new_boots
		emit_changed()

@export var weapon_right: OwnedGear:
	set(new_weapon_right):
		weapon_right = new_weapon_right
		emit_changed()

@export var weapon_left: OwnedGear:
	set(new_weapon_left):
		weapon_left = new_weapon_left
		emit_changed()

# ── Rarity offset ─────────────────────────────────────────────────────────────

## Tracks the STS-style rarity offset for card reward rolls.
## Starts at -5.0. Increases by 1 each time a Common is rolled in a reward screen.
## Resets to -5.0 when a Rare is rolled. Persists across all combats in a run.
@export var rarity_offset: float = -5.0:
	set(new_rarity_offset):
		rarity_offset = new_rarity_offset
		emit_changed()

# ── Floor sequence ─────────────────────────────────────────────────────────────

## Resource paths for every FloorData in the run's sequence, in order.
@export var floor_sequence_paths: Array[String] = []:
	set(new_floor_sequence_paths):
		floor_sequence_paths = new_floor_sequence_paths
		emit_changed()

# ── Pending stash items ────────────────────────────────────────────────────────
## Gear found during the run that the player chose not to equip immediately.
## Added to CharacterSaveData.gear_stash at run end.
@export var pending_stash: Array[OwnedGear] = []:
	set(new_pending_stash):
		pending_stash = new_pending_stash
		emit_changed()
