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
	CLEAR_BLOCK,     ## Remove all block from target (value unused)
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

## The damage subtype. Combat resolver applies class-specific multipliers.
## e.g. HOLY deals double damage to undead-tagged enemies.
enum DamageType {
	PHYSICAL,
	HOLY,
}

## Where the effect's magnitude comes from at resolve-time.
## FIXED uses the value/upgraded_value fields directly.
## All other sources are supplied by the combat system at the moment of resolution.
enum ValueSource {
	FIXED,                   ## Use value / upgraded_value
	CURRENT_HP,              ## Player's current HP at time of resolution
	CURRENT_BLOCK,           ## Player's current block at time of resolution
	LIFE_GAINED_THIS_COMBAT, ## Total HP restored since combat began
	TRIGGER_AMOUNT,          ## The magnitude of the event that fired this trigger (e.g. HP healed by ON_HEAL)
}

## When set, playing this card installs a persistent listener for the rest of combat
## rather than resolving the effect immediately. Used by Power / Blessing cards.
## The effect_type and value fields describe what fires when the trigger activates.
enum PowerTrigger {
	NONE,           ## Effect resolves immediately on play (normal cards)
	TURN_START,     ## Fires at the start of each subsequent player turn
	ON_HEAL,        ## Fires whenever the player gains HP
	ON_CARD_PLAYED, ## Fires whenever the player plays a card
}

@export var effect_type: EffectType = EffectType.DAMAGE:
	set(new_effect_type):
		effect_type = new_effect_type
		emit_changed()

## Base value when the card is not upgraded.
## For FIXED value_source this is the resolved magnitude.
## For scaling sources this acts as a display/fallback value on the card face.
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

## For DAMAGE effects: the damage subtype. Defaults to PHYSICAL.
@export var damage_type: DamageType = DamageType.PHYSICAL:
	set(new_damage_type):
		damage_type = new_damage_type
		emit_changed()

## Where the effect magnitude comes from at resolve-time.
@export var value_source: ValueSource = ValueSource.FIXED:
	set(new_value_source):
		value_source = new_value_source
		emit_changed()

## When non-NONE, this effect is a persistent trigger installed on play.
@export var power_trigger: PowerTrigger = PowerTrigger.NONE:
	set(new_power_trigger):
		power_trigger = new_power_trigger
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

## Returns the fixed value based on whether the card is upgraded.
## Only meaningful when value_source == ValueSource.FIXED.
## For scaling sources the combat system supplies the real value at resolution time.
func resolved_value(is_upgraded: bool) -> int:
	if is_upgraded and upgraded_value >= 0:
		return upgraded_value
	return value
