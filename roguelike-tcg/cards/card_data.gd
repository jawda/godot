@tool
class_name CardData
extends Resource

enum Rarity    { COMMON, UNCOMMON, RARE, MYTHIC, SPECIAL }
enum CardType  { ATTACK, QUIRK, POWER, CURSE, STATUS, DEFENSE }
enum CardClass { NEUTRAL, CLERIC }

@export_group("Card Data")
@export var card_name: String = "New Card":
	set(new_card_name):
		card_name = new_card_name
		emit_changed()

@export var card_cost: int = 0:
	set(new_card_cost):
		card_cost = new_card_cost
		emit_changed()

@export var card_type: CardType = CardType.ATTACK:
	set(new_card_type):
		card_type = new_card_type
		emit_changed()

## Description template. Use {0}, {1}, … to reference effect values in order.
## Example: "Deal [b]{0}[/b] damage." — {0} resolves to effects[0].value.
## Cards with no {N} tokens display their description as plain BBCode (backward compatible).
@export_multiline var card_description: String = "":
	set(new_card_description):
		card_description = new_card_description
		emit_changed()

## The effects this card applies when played, in order.
## {0} in card_description resolves to effects[0], {1} to effects[1], etc.
@export var effects: Array[CardEffect] = []:
	set(new_effects):
		for existing_effect in effects:
			if existing_effect and existing_effect.changed.is_connected(_on_effect_changed):
				existing_effect.changed.disconnect(_on_effect_changed)
		effects = new_effects
		for new_effect in effects:
			if new_effect:
				new_effect.changed.connect(_on_effect_changed)
		emit_changed()

## When true this card is a token — created at runtime by another card effect,
## not part of the base deck. Tokens are removed from the deck at end of combat.
@export var is_token: bool = false:
	set(new_is_token):
		is_token = new_is_token
		emit_changed()

## When false this card never appears in combat reward pools.
## Set to false on starter/basic cards (Strike, Defend, Mace Strike, Ward, Prayer, etc.).
@export var in_reward_pool: bool = true:
	set(new_in_reward_pool):
		in_reward_pool = new_in_reward_pool
		emit_changed()

## Which player class this card belongs to. NEUTRAL cards appear in all draft pools.
@export var card_class: CardClass = CardClass.NEUTRAL:
	set(new_card_class):
		card_class = new_card_class
		emit_changed()

func _on_effect_changed() -> void:
	emit_changed()

## Returns the display label for this card's type, accounting for class-specific terminology.
## e.g. Cleric POWER cards display as "Blessing" rather than "Power".
func get_type_label() -> String:
	if card_class == CardClass.CLERIC and card_type == CardType.POWER:
		return "Blessing"
	match card_type:
		CardType.ATTACK:  return "Attack"
		CardType.QUIRK:   return "Quirk"
		CardType.POWER:   return "Power"
		CardType.CURSE:   return "Curse"
		CardType.STATUS:  return "Status"
		CardType.DEFENSE: return "Defense"
	return ""

## Returns card_description with {N} tokens replaced by the resolved effect values.
## Pass the card's current upgraded state so upgraded values are used when appropriate.
func get_description(is_upgraded: bool = false) -> String:
	var result: String = card_description
	for effect_index in effects.size():
		if effects[effect_index]:
			result = result.replace("{%d}" % effect_index, str(effects[effect_index].resolved_value(is_upgraded)))
	return result

@export_group("Rarity")
@export var base_rarity: Rarity = Rarity.COMMON:
	set(new_base_rarity):
		base_rarity = new_base_rarity
		emit_changed()

@export var upgraded: bool = false:
	set(new_upgraded):
		upgraded = new_upgraded
		emit_changed()

## Cost when upgraded. -1 means the same as card_cost.
@export var upgraded_cost: int = -1:
	set(new_upgraded_cost):
		upgraded_cost = new_upgraded_cost
		emit_changed()

var effective_cost: int:
	get: return upgraded_cost if (upgraded and upgraded_cost >= 0) else card_cost

var effective_rarity: Rarity:
	get: return mini(base_rarity + 1, Rarity.SPECIAL) as Rarity if upgraded else base_rarity
