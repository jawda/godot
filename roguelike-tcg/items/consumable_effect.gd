class_name ConsumableEffect
extends Resource

## What a consumable does when used.
## A single ConsumableData can have multiple effects — e.g. Holy Water restores HP
## and deals damage. Each effect is resolved in order when the item is consumed.

enum EffectType {
	RESTORE_HP,           ## Restore [value] HP.
	DEAL_DAMAGE,          ## Deal [value] damage. param = damage type ("normal", "holy").
	GAIN_STAT,            ## Gain +[value] to a stat for this combat. param = stat name.
	GAIN_BLOCK,           ## Gain [value] block immediately.
	DRAW_CARDS,           ## Draw [value] cards immediately.
	BONUS_ATTACK_DAMAGE,  ## All attacks deal +[value] damage for the rest of this combat.
	SCALE_HEALS,          ## The next [count] heal effects are multiplied by [value].
	EXTRA_CARDS_PER_TURN, ## Draw [value] extra cards at the start of each turn (rest of combat).
	DAMAGE_PER_TURN,      ## Take [value] damage at the start of each turn (rest of combat).
}

@export var effect_type: EffectType = EffectType.RESTORE_HP:
	set(new_effect_type):
		effect_type = new_effect_type
		emit_changed()

## Primary numeric value — HP restored, damage dealt, stat bonus, etc.
@export var value: int = 0:
	set(new_value):
		value = new_value
		emit_changed()

## For SCALE_HEALS: how many heal effects to scale before expiring.
## Ignored by all other effect types.
@export var count: int = 0:
	set(new_count):
		count = new_count
		emit_changed()

## For GAIN_STAT: the stat to buff (e.g. "strength", "faith").
## For DEAL_DAMAGE: the damage type (e.g. "normal", "holy").
@export var param: String = "":
	set(new_param):
		param = new_param
		emit_changed()
