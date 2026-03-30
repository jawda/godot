@tool
class_name PlayerData
extends Resource

# ── Character identity ─────────────────────────────────────────────────────────

@export_group("Character")
@export var character_name: String = "Unknown":
	set(new_character_name):
		character_name = new_character_name
		emit_changed()

@export var character_class: String = "":
	set(new_character_class):
		character_class = new_character_class
		emit_changed()

@export_multiline var character_description: String = "":
	set(new_character_description):
		character_description = new_character_description
		emit_changed()

## The deck this character starts every run with.
@export var starter_deck: DeckData:
	set(new_starter_deck):
		starter_deck = new_starter_deck
		emit_changed()

# ── Base stats ─────────────────────────────────────────────────────────────────
# These are the character's starting values before any gear or combat modifiers.
# The runtime adds gear bonuses and temporary combat modifiers on top at play time.

@export_group("Base Stats")

## Increases damage dealt by attacks.
@export var strength: int = 0:
	set(new_strength):
		strength = new_strength
		emit_changed()

## Increases block gained and evasion (evasion functions as block until distinguished).
@export var dexterity: int = 0:
	set(new_dexterity):
		dexterity = new_dexterity
		emit_changed()

## Increases maximum HP. Also increases resistance to status effects (TBD scaling).
@export var constitution: int = 0:
	set(new_constitution):
		constitution = new_constitution
		emit_changed()

## Effect TBD — reserved for card synergies and spell scaling.
@export var intelligence: int = 0:
	set(new_intelligence):
		intelligence = new_intelligence
		emit_changed()

## Effect TBD — reserved for card synergies and divine/curse scaling.
@export var faith: int = 0:
	set(new_faith):
		faith = new_faith
		emit_changed()

## Base critical hit chance as a percentage. Gear and effects may increase this at runtime.
@export var base_crit_chance: float = 5.0:
	set(new_base_crit_chance):
		base_crit_chance = new_base_crit_chance
		emit_changed()

# ── Health ─────────────────────────────────────────────────────────────────────

@export_group("Health")

## Base maximum HP before constitution scaling.
## Runtime formula: max_hp = base_max_health + (constitution * HP_PER_CONSTITUTION)
@export var base_max_health: int = 80:
	set(new_base_max_health):
		base_max_health = new_base_max_health
		emit_changed()

# ── Starting gear ──────────────────────────────────────────────────────────────
# Gear slots start empty (null) for most characters. Assign a GearData resource
# here if the character begins a run with a specific item already equipped.

@export_group("Starting Gear")

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
