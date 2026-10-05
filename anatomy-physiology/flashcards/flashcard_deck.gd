class_name FlashcardDeck
extends MarginContainer
## Flip-card drill. "Still learning" sends the card to the back of the deck;
## "Know it" removes it and remembers it as known.

var _all_cards: Array[Flashcard] = []
var _queue: Array[Flashcard] = []
var _showing_back: bool = false
var _known_this_round: int = 0

# ── Node references ──
@onready var _counter: Label = $Layout/Toolbar/Counter
@onready var _definition_first: CheckButton = $Layout/Toolbar/DefinitionFirst
@onready var _hide_known: CheckButton = $Layout/Toolbar/HideKnown
@onready var _restart: Button = $Layout/Toolbar/Restart
@onready var _card: Button = $Layout/Card
@onready var _hint: Label = $Layout/Hint
@onready var _still_learning: Button = $Layout/Grading/StillLearning
@onready var _know_it: Button = $Layout/Grading/KnowIt


func _ready() -> void:
	_card.pressed.connect(_flip)
	_still_learning.pressed.connect(_grade.bind(false))
	_know_it.pressed.connect(_grade.bind(true))
	_restart.pressed.connect(_restart_deck)
	_definition_first.toggled.connect(func(_is_on: bool) -> void: _show_current_card())
	_hide_known.toggled.connect(func(_is_on: bool) -> void: _restart_deck())


func load_deck(cards: Array[Flashcard]) -> void:
	_all_cards = cards
	_restart_deck()


func _restart_deck() -> void:
	_queue.clear()
	for card: Flashcard in _all_cards:
		if _hide_known.button_pressed and StudyProgress.is_flashcard_known(card.id):
			continue
		_queue.append(card)
	_queue.shuffle()
	_known_this_round = 0
	_show_current_card()


func _show_current_card() -> void:
	_showing_back = false
	if _queue.is_empty():
		_show_finished()
		return
	var card: Flashcard = _queue.front()
	_card.disabled = false
	_card.text = card.definition if _definition_first.button_pressed else card.term
	_card.theme_type_variation = &"FlashcardBack" if _definition_first.button_pressed else &"FlashcardFace"
	_hint.text = "Click the card or press Space to flip it."
	_set_grading_enabled(false)
	_update_counter()


func _flip() -> void:
	if _queue.is_empty():
		return
	var card: Flashcard = _queue.front()
	_showing_back = not _showing_back
	var showing_definition: bool = _showing_back != _definition_first.button_pressed
	_card.text = card.definition if showing_definition else card.term
	_card.theme_type_variation = &"FlashcardBack" if showing_definition else &"FlashcardFace"
	_hint.text = "Did you get it? Press 1 for still learning, 2 if you know it."
	_set_grading_enabled(true)


func _grade(is_known: bool) -> void:
	if _queue.is_empty() or not _showing_back:
		return
	var card: Flashcard = _queue.pop_front()
	if is_known:
		_known_this_round += 1
		StudyProgress.set_flashcard_known(card.id, true)
	else:
		StudyProgress.set_flashcard_known(card.id, false)
		_queue.push_back(card)
	_show_current_card()


func _show_finished() -> void:
	_card.disabled = true
	_set_grading_enabled(false)
	if _all_cards.is_empty():
		_card.text = "This module has no flashcards yet."
	elif _known_this_round == 0:
		_card.text = "Every card is already marked as known.\nTurn off \"Hide known cards\" to review them all."
	else:
		_card.text = "Deck complete!\nYou worked through %d cards." % _known_this_round
	_hint.text = "Shuffle & restart to go again."
	_update_counter()


func _update_counter() -> void:
	var known_total: int = 0
	for card: Flashcard in _all_cards:
		if StudyProgress.is_flashcard_known(card.id):
			known_total += 1
	_counter.text = "%d left in this round  ·  %d of %d known overall" % [
		_queue.size(), known_total, _all_cards.size()]


func _set_grading_enabled(is_enabled: bool) -> void:
	_still_learning.disabled = not is_enabled
	_know_it.disabled = not is_enabled
