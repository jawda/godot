@tool
class_name GearEffect
extends Resource

## When this effect activates during combat.
enum Trigger {
	PASSIVE,       ## Always active — use for flat stat bonuses
	COMBAT_START,  ## Triggers once when combat begins
	TURN_START,    ## Triggers at the start of each player turn
	ON_KILL,       ## Triggers when an enemy dies
}

## What the effect does when it triggers.
enum EffectType {
	STAT_BONUS,    ## Increase a stat by value (param = stat name e.g. "strength")
	EXTRA_DRAW,    ## Draw additional cards
	GAIN_BLOCK,    ## Gain X block
	DEAL_DAMAGE,   ## Deal X damage to the current enemy
	APPLY_STATUS,  ## Apply X stacks of a status (param = status id e.g. "burn")
}

@export var trigger: Trigger = Trigger.PASSIVE:
	set(new_trigger):
		trigger = new_trigger
		emit_changed()

@export var effect_type: EffectType = EffectType.STAT_BONUS:
	set(new_effect_type):
		effect_type = new_effect_type
		emit_changed()

## Base value when the item is not upgraded.
@export var value: int = 0:
	set(new_value):
		value = new_value
		emit_changed()

## Value when the item is upgraded. Set to -1 to use the same value as base.
@export var upgraded_value: int = -1:
	set(new_upgraded_value):
		upgraded_value = new_upgraded_value
		emit_changed()

## For STAT_BONUS: which stat to increase (e.g. "strength", "dexterity").
## For APPLY_STATUS: which status to apply (e.g. "burn", "void").
@export var param: String = "":
	set(new_param):
		param = new_param
		emit_changed()

## Returns the correct value based on whether the item is upgraded.
func resolved_value(is_upgraded: bool) -> int:
	if is_upgraded and upgraded_value >= 0:
		return upgraded_value
	return value
