class_name RunSaveData
extends Resource

@export var current_health: int = 0:
	set(new_current_health):
		current_health = new_current_health
		emit_changed()

@export var current_max_health: int = 0:
	set(new_current_max_health):
		current_max_health = new_current_max_health
		emit_changed()

@export var current_floor: int = 1:
	set(new_current_floor):
		current_floor = new_current_floor
		emit_changed()

@export var gold: int = 0:
	set(new_gold):
		gold = new_gold
		emit_changed()

## Paths to CardData .tres files representing the player's current deck.
## This array changes over the course of a run as cards are added or removed.
@export var deck_card_paths: Array[String] = []:
	set(new_deck_card_paths):
		deck_card_paths = new_deck_card_paths
		emit_changed()
