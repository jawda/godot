class_name Deck
extends RefCounted

const MIN_SIZE: int = 10
const MAX_SIZE: int = 40

# ── Internal state ─────────────────────────────────────────────────────────────

var _all_cards: Array[CardData] = []
var _draw_pile: Array[CardData] = []
var _discard_pile: Array[CardData] = []

# ── Setup ──────────────────────────────────────────────────────────────────────

func load_from_data(deck_data: DeckData) -> void:
	_all_cards.clear()
	for card_data: CardData in deck_data.starter_cards:
		_all_cards.append(card_data)
	_draw_pile = _all_cards.duplicate()
	_discard_pile.clear()
	shuffle()

func shuffle() -> void:
	_draw_pile.shuffle()

# ── Draw / discard ─────────────────────────────────────────────────────────────

## Returns the top card of the draw pile.
## If the draw pile is empty, the discard pile is reshuffled back in automatically.
## Returns null only if both piles are empty.
func draw_card() -> CardData:
	if _draw_pile.is_empty():
		if _discard_pile.is_empty():
			return null
		reshuffle_discard_into_draw()
	return _draw_pile.pop_back()

func discard_card(card_data: CardData) -> void:
	_discard_pile.append(card_data)

## Moves all discarded cards back into the draw pile and shuffles.
func reshuffle_discard_into_draw() -> void:
	_draw_pile.append_array(_discard_pile)
	_discard_pile.clear()
	shuffle()

# ── Deck modification (store / event only) ────────────────────────────────────

## Adds a card to the deck. Returns true on success, false if deck is at MAX_SIZE.
func add_card(card_data: CardData) -> bool:
	if _all_cards.size() >= MAX_SIZE:
		return false
	_all_cards.append(card_data)
	_draw_pile.append(card_data)
	return true

## Removes a card from the deck (store/event use only).
## Returns true on success, false if the card is not in the deck or removal would
## drop the deck below MIN_SIZE.
func remove_card(card_data: CardData) -> bool:
	if _all_cards.size() <= MIN_SIZE:
		return false
	var index: int = _all_cards.find(card_data)
	if index == -1:
		return false
	_all_cards.remove_at(index)
	# Remove from whichever pile currently holds it
	var draw_index: int = _draw_pile.find(card_data)
	if draw_index != -1:
		_draw_pile.remove_at(draw_index)
	else:
		var discard_index: int = _discard_pile.find(card_data)
		if discard_index != -1:
			_discard_pile.remove_at(discard_index)
	return true

# ── Queries ────────────────────────────────────────────────────────────────────

func draw_pile_count() -> int:
	return _draw_pile.size()

func discard_pile_count() -> int:
	return _discard_pile.size()

func total_count() -> int:
	return _all_cards.size()

func get_all_cards() -> Array[CardData]:
	return _all_cards.duplicate()

func get_draw_pile() -> Array[CardData]:
	return _draw_pile.duplicate()

func get_discard_pile() -> Array[CardData]:
	return _discard_pile.duplicate()
