class_name CombatPlayer
extends RefCounted

## Per-constitution HP increase applied at combat start.
const HP_PER_CONSTITUTION: int = 10
## Default energy per turn.
const BASE_MAX_ENERGY: int = 3
## Each Faith point adds 10% to life gained (Faith 3 = +30%).
const FAITH_HEAL_MULTIPLIER: float = 0.1

# ── Stats ───────────────────────────────────────────────────────────────────────

var max_health: int = 0
var current_health: int = 0
var current_block: int = 0
var max_energy: int = BASE_MAX_ENERGY
var current_energy: int = 0

## HP restored since combat began. Used by LIFE_GAINED_THIS_COMBAT value source.
var life_gained_this_combat: int = 0

var strength: int = 0
var dexterity: int = 0
var faith: int = 0

## Active status effects — key: status name, value: stack count.
## e.g. { "vulnerable": 2, "weak": 1, "burn": 3 }
var statuses: Dictionary = {}

# ── Setup ───────────────────────────────────────────────────────────────────────

## Initialises combat state from a PlayerData resource.
## Pass run_data to include level-up stat bonuses earned during the run.
## Pass current_run_health to restore mid-run health; -1 uses full max health.
func setup(player_data: PlayerData, current_run_health: int = -1, run_data: RunSaveData = null) -> void:
	var bonus_con: int   = run_data.bonus_constitution if run_data != null else 0
	max_health = player_data.base_max_health + (player_data.constitution + bonus_con) * HP_PER_CONSTITUTION
	current_health = current_run_health if current_run_health > 0 else max_health
	current_block = 0
	current_energy = max_energy
	life_gained_this_combat = 0
	strength = player_data.strength + (run_data.bonus_strength if run_data != null else 0)
	dexterity = player_data.dexterity + (run_data.bonus_dexterity if run_data != null else 0)
	faith = player_data.faith + (run_data.bonus_faith if run_data != null else 0)
	statuses.clear()

# ── Combat interface ────────────────────────────────────────────────────────────

## Applies incoming damage, absorbing through block first.
func take_damage(amount: int) -> void:
	var absorbed: int = mini(current_block, amount)
	current_block -= absorbed
	current_health -= (amount - absorbed)
	current_health = maxi(current_health, 0)

## Restores HP scaled by Faith. Returns the actual amount healed.
## Faith scaling: base × (1 + Faith × 0.1). Capped at missing HP.
func heal(amount: int) -> int:
	var scaled: int = roundi(amount * (1.0 + faith * FAITH_HEAL_MULTIPLIER))
	var actual: int = mini(scaled, max_health - current_health)
	current_health += actual
	life_gained_this_combat += actual
	return actual

## Adds block. Each point of dexterity adds 1 bonus block per gain.
func gain_block(amount: int) -> void:
	current_block += amount + dexterity

func clear_block() -> void:
	current_block = 0

## Deducts energy cost. Returns false (without spending) if insufficient energy.
func spend_energy(cost: int) -> bool:
	if current_energy < cost:
		return false
	current_energy -= cost
	return true

func refill_energy() -> void:
	current_energy = max_energy

func apply_status(status_name: String, stacks: int) -> void:
	statuses[status_name] = statuses.get(status_name, 0) + stacks

func get_status(status_name: String) -> int:
	return statuses.get(status_name, 0)

## Ticks DoT and duration statuses at the start of the player's turn.
## Call this before dealing DoT damage so the damage can be read externally first.
func tick_statuses() -> void:
	var to_remove: Array[String] = []
	for key: String in statuses:
		match key:
			"burn", "bleed", "void", "weak", "vulnerable":
				statuses[key] -= 1
				if statuses[key] <= 0:
					to_remove.append(key)
	for key: String in to_remove:
		statuses.erase(key)

func is_dead() -> bool:
	return current_health <= 0
