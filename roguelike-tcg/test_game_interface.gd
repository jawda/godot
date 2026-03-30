extends Control

const STARTER_DECK_DATA: DeckData = preload("res://decks/data/starter_deck.tres")

@onready var _hand: Hand = $Hand

const STARTING_HAND_SIZE: int = 5

func _ready() -> void:
	var deck: Deck = Deck.new()
	deck.load_from_data(STARTER_DECK_DATA)
	_hand.set_deck(deck)
	_hand.draw_multiple(STARTING_HAND_SIZE)


func _on_draw_card_button_pressed() -> void:
	_hand.draw()


func _on_reset_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_discard_card_button_pressed() -> void:
	_hand.discard()
