class_name EventOutcome
extends Resource

## A single effect applied when an EventChoice is made.
## Choices can have multiple outcomes — e.g. lose 10 HP and gain 2 cards.

enum OutcomeType {
	GAIN_GOLD,       ## Gain [value] gold.
	LOSE_GOLD,       ## Lose [value] gold.
	GAIN_HP,         ## Restore [value] HP.
	LOSE_HP,         ## Lose [value] HP.
	GAIN_XP_PERCENT, ## Gain [value]% of the current level's XP requirement.
	GAIN_CARD,       ## Add a card to the deck. param = card .tres path or a tag:
	                 ##   "random_class_card"  — random card from the player's class pool
	                 ##   "random_rare_card"   — random rare or above from class pool
	                 ##   "random_curse"       — a random curse card
	REMOVE_CARD,     ## Player chooses one card to permanently remove from their deck.
	UPGRADE_CARD,    ## Player chooses one card in their deck to upgrade.
	GAIN_CONSUMABLE, ## Add a consumable to the potion belt. param = consumable .tres path.
	APPLY_STATUS,    ## Apply [value] stacks of the status named [param] to the player.
}

@export var outcome_type: OutcomeType = OutcomeType.GAIN_GOLD:
	set(new_outcome_type):
		outcome_type = new_outcome_type
		emit_changed()

@export var value: int = 0:
	set(new_value):
		value = new_value
		emit_changed()

## For GAIN_CARD: card path or tag. For GAIN_CONSUMABLE: consumable path.
## For APPLY_STATUS: status id (e.g. "weak", "burn").
@export var param: String = "":
	set(new_param):
		param = new_param
		emit_changed()
