class_name MasteryEffect
extends Resource

## A single triggered or passive effect granted by a Mastery.
## A MasteryData can have multiple effects — e.g. a mastery that heals on kill
## and also draws a card on kill would use two effects with the same trigger.

enum Trigger {
	PASSIVE,         ## Always active — used for flat stat bonuses and modifiers.
	COMBAT_START,    ## Fires once when combat begins.
	TURN_START,      ## Fires at the start of each player turn.
	ON_ENEMY_KILLED, ## Fires when the player kills an enemy.
	ON_BLOCK_GAINED, ## Fires whenever the player gains block from any source.
	ON_CARD_PLAYED,  ## Fires when a card is played. param filters to a specific card type.
	ON_TAKE_DAMAGE,  ## Fires when the player takes damage.
	ON_HEAL,         ## Fires when the player is healed.
	ON_WOULD_DIE,    ## Fires when damage would reduce the player to 0 HP or below.
}

enum EffectType {
	RESTORE_HP,           ## Restore [value] HP.
	GAIN_BLOCK,           ## Gain [value] block.
	BONUS_BLOCK_PER_STAT, ## Gain [value] bonus block per point of [param] stat.
	BONUS_DAMAGE_PER_STAT,## Deal [value] bonus damage per point of [param] stat.
	PREVENT_DEATH,        ## Survive at 1 HP instead of dying. Respects [charges] per combat.
	APPLY_STATUS,         ## Apply [value] stacks of the status named [param].
	DRAW_CARDS,           ## Draw [value] cards.
	STAT_BONUS,           ## Increase [param] stat by [value] for the rest of this combat.
	REDUCE_CARD_COST,     ## Cards of the type named [param] cost [value] less energy.
}

@export var trigger: Trigger = Trigger.PASSIVE:
	set(new_trigger):
		trigger = new_trigger
		emit_changed()

@export var effect_type: EffectType = EffectType.RESTORE_HP:
	set(new_effect_type):
		effect_type = new_effect_type
		emit_changed()

@export var value: int = 0:
	set(new_value):
		value = new_value
		emit_changed()

## How many times this effect can fire per combat. 0 = unlimited.
## Reset to full at the start of each combat.
@export var charges: int = 0:
	set(new_charges):
		charges = new_charges
		emit_changed()

## For BONUS_BLOCK_PER_STAT / BONUS_DAMAGE_PER_STAT / STAT_BONUS: the stat name
##   (e.g. "faith", "strength").
## For APPLY_STATUS: the status id (e.g. "burn", "weak").
## For REDUCE_CARD_COST: the card type name (e.g. "ATTACK", "DEFENSE").
## For ON_CARD_PLAYED trigger: filter to this card type only. Empty = any card.
@export var param: String = "":
	set(new_param):
		param = new_param
		emit_changed()
