class_name CharacterSaveData
extends Resource

## Path to the character's PlayerData .tres resource (e.g. "res://player/data/warrior.tres").
@export var character_id: String = "":
	set(new_character_id):
		character_id = new_character_id
		emit_changed()

# ── Gear slots ─────────────────────────────────────────────────────────────────

@export var helmet: GearData:
	set(new_helmet):
		helmet = new_helmet
		emit_changed()

@export var necklace: GearData:
	set(new_necklace):
		necklace = new_necklace
		emit_changed()

@export var ring_left: GearData:
	set(new_ring_left):
		ring_left = new_ring_left
		emit_changed()

@export var ring_right: GearData:
	set(new_ring_right):
		ring_right = new_ring_right
		emit_changed()

@export var armor: GearData:
	set(new_armor):
		armor = new_armor
		emit_changed()

@export var weapon: GearData:
	set(new_weapon):
		weapon = new_weapon
		emit_changed()

# ── Active run ─────────────────────────────────────────────────────────────────

## The player's current run snapshot. Null when no run is in progress.
@export var active_run: RunSaveData:
	set(new_active_run):
		active_run = new_active_run
		emit_changed()
