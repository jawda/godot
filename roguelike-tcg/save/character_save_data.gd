class_name CharacterSaveData
extends Resource

## Persistent per-character data that survives across all runs.
## Gear (equipped slots + stash) persists on death. Runs do not.

## Path to the character's PlayerData .tres resource (e.g. "res://player/characters/cleric.tres").
@export var character_id: String = "":
	set(new_character_id):
		character_id = new_character_id
		emit_changed()

## Highest difficulty tier this character has cleared. 0 = base game only.
@export var difficulty_tier: int = 0:
	set(new_difficulty_tier):
		difficulty_tier = new_difficulty_tier
		emit_changed()

# ── Default loadout ────────────────────────────────────────────────────────────
# These slots represent the gear the character starts a run with.
# At run start they are copied into RunSaveData. At run end the run's
# final slots are written back here.

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

# ── Gear stash ─────────────────────────────────────────────────────────────────
## All gear owned by this character that is not currently equipped.
## Persists indefinitely — gear is never lost on death.
@export var gear_stash: Array[OwnedGear] = []:
	set(new_gear_stash):
		gear_stash = new_gear_stash
		emit_changed()

# ── Active run ─────────────────────────────────────────────────────────────────
## The player's current run snapshot. Null when no run is in progress.
@export var active_run: RunSaveData:
	set(new_active_run):
		active_run = new_active_run
		emit_changed()
