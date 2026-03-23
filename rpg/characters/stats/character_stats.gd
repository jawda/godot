class_name CharacterStats
extends Node

## Runtime stat component. Attach to any character node.
## Reads base values from a CharacterStatsData resource and exposes
## derived stats (max_hp, attack, etc.) as computed properties.
## Emits signals when stats change so UI and gameplay systems can react.

signal stat_changed(stat_name: String, old_value: int, new_value: int)
signal health_changed(current_hp: int, max_hp: int)
signal died

@export var base_stats: CharacterStatsData

# --- Current HP (runtime only) ---
var current_hp: int

# --- Base stat accessors ---

var strength: int:
	get: return base_stats.strength if base_stats else 0
	set(v):
		var old := strength
		base_stats.strength = clampi(v, 1, 99)
		if old != base_stats.strength:
			stat_changed.emit("strength", old, base_stats.strength)

var dexterity: int:
	get: return base_stats.dexterity if base_stats else 0
	set(v):
		var old := dexterity
		base_stats.dexterity = clampi(v, 1, 99)
		if old != base_stats.dexterity:
			stat_changed.emit("dexterity", old, base_stats.dexterity)

var vigor: int:
	get: return base_stats.vigor if base_stats else 0
	set(v):
		var old := vigor
		base_stats.vigor = clampi(v, 1, 99)
		if old != base_stats.vigor:
			stat_changed.emit("vigor", old, base_stats.vigor)

var faith: int:
	get: return base_stats.faith if base_stats else 0
	set(v):
		var old := faith
		base_stats.faith = clampi(v, 1, 99)
		if old != base_stats.faith:
			stat_changed.emit("faith", old, base_stats.faith)

var intelligence: int:
	get: return base_stats.intelligence if base_stats else 0
	set(v):
		var old := intelligence
		base_stats.intelligence = clampi(v, 1, 99)
		if old != base_stats.intelligence:
			stat_changed.emit("intelligence", old, base_stats.intelligence)

var charisma: int:
	get: return base_stats.charisma if base_stats else 0
	set(v):
		var old := charisma
		base_stats.charisma = clampi(v, 1, 99)
		if old != base_stats.charisma:
			stat_changed.emit("charisma", old, base_stats.charisma)

# --- Derived stats ---

## Max HP scales with Vigor (base 50 + 10 per point above 10, tapering at high values)
var max_hp: int:
	get: return 50 + vigor * 10

## Physical attack power, primarily Strength with a Dexterity contribution
var physical_attack: int:
	get: return strength * 2 + dexterity / 2

## Magic power, primarily Intelligence with a Faith contribution
var magic_attack: int:
	get: return intelligence * 2 + faith / 2

## Dodge / evasion chance (0–100), scales with Dexterity
var evasion: int:
	get: return clampi(dexterity / 2, 0, 75)

## Persuasion / barter modifier, scales with Charisma
var persuasion_bonus: int:
	get: return charisma - 10  # positive above 10, negative below


func _ready() -> void:
	assert(base_stats != null, "CharacterStats: base_stats resource must be set.")
	current_hp = max_hp


# --- HP helpers ---

func take_damage(amount: int) -> void:
	var old_hp := current_hp
	current_hp = clampi(current_hp - amount, 0, max_hp)
	health_changed.emit(current_hp, max_hp)
	if current_hp == 0 and old_hp > 0:
		died.emit()


func heal(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp)
	health_changed.emit(current_hp, max_hp)


func is_alive() -> bool:
	return current_hp > 0


func restore_full_hp() -> void:
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)
