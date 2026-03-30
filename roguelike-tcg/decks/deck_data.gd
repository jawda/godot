@tool
class_name DeckData
extends Resource

# class_id will map to a player class once classes are designed.
# Leave empty for the default starter deck available to all classes.
@export var deck_name: String = "New Deck"
@export_multiline var description: String = ""
@export var class_id: String = ""

@export_group("Cards")
@export var starter_cards: Array[CardData] = []
