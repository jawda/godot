@tool
class_name CardEffect
extends Resource

enum EffectType {
	DAMAGE,          ## Deal X damage to target
	BLOCK,           ## Gain X block
	DRAW,            ## Draw X cards
	HEAL,            ## Restore X HP
	APPLY_STATUS,    ## Apply X stacks of a status effect
	STAT_UP,         ## Increase a stat by X for the rest of combat
	GENERATE_TOKEN,  ## Add a copy of token_data to the chosen destination
}

enum Target {
	SELF,
	ENEMY,
	ALL_ENEMIES,
}

## Where a generated token card is placed when the effect resolves.
enum TokenDestination {
	HAND,
	DRAW_PILE,
	DISCARD_PILE,
}

@export var effect_type: EffectType = EffectType.DAMAGE:
	set(new_effect_type):
		effect_type = new_effect_type
		emit_changed()

## Base value when the card is not upgraded.
@export var value: int = 0:
	set(new_value):
		value = new_value
		emit_changed()

## Value when the card is upgraded. Set to -1 to use the same value as base.
@export var upgraded_value: int = -1:
	set(new_upgraded_value):
		upgraded_value = new_upgraded_value
		emit_changed()

@export var target: Target = Target.ENEMY:
	set(new_target):
		target = new_target
		emit_changed()

## For APPLY_STATUS: which status to apply (e.g. "void", "burn", "bleed").
## For STAT_UP: which stat to modify (e.g. "strength", "dexterity").
@export var param: String = "":
	set(new_param):
		param = new_param
		emit_changed()

## For GENERATE_TOKEN: the CardData resource that defines the generated card.
@export var token_data: CardData:
	set(new_token_data):
		token_data = new_token_data
		emit_changed()

## For GENERATE_TOKEN: where the generated card is placed when the effect resolves.
@export var token_destination: TokenDestination = TokenDestination.HAND:
	set(new_token_destination):
		token_destination = new_token_destination
		emit_changed()

## Returns the correct value based on whether the card is upgraded.
func resolved_value(is_upgraded: bool) -> int:
	if is_upgraded and upgraded_value >= 0:
		return upgraded_value
	return value
