class_name Hand
extends ColorRect

const CARD: PackedScene = preload("res://cards/card.tscn")
const MAX_HAND_SIZE: int = 10

@export var hand_curve: Curve
@export var rotation_curve: Curve

@export var max_rotation_degrees: int = 5
@export var x_sep: int = -10
@export var y_min: int = 0
@export var y_max: int = -35

var _deck: Deck = null
var _focused_card: Card = null

# Resting positions are the layout positions before any hover animation.
# Hover detection uses these so rotation and card lift don't affect hit testing.
var _resting_positions: Array[Vector2] = []

func set_deck(deck: Deck) -> void:
	_deck = deck

# ── Input ──────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_pos: Vector2 = get_local_mouse_position()
		_set_focus(_card_at_position(mouse_pos))
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var card_count: int = get_child_count()
		if card_count == 0:
			return
		var current_index: int = _focused_card.get_index() if _focused_card != null else -1
		var new_index: int
		if event.is_action_pressed("ui_left"):
			new_index = max(0, current_index - 1) if current_index >= 0 else card_count - 1
		else:
			new_index = min(card_count - 1, current_index + 1) if current_index >= 0 else 0
		_set_focus(get_child(new_index) as Card)
		get_viewport().set_input_as_handled()

## Returns the topmost card whose resting rect contains pos, or null.
## Checks in reverse child order so later (top-rendered) cards win overlapping areas.
func _card_at_position(pos: Vector2) -> Card:
	for card_index: int in range(get_child_count() - 1, -1, -1):
		if card_index >= _resting_positions.size():
			continue
		if Rect2(_resting_positions[card_index], Card.SIZE).has_point(pos):
			return get_child(card_index) as Card
	return null

# ── Focus ──────────────────────────────────────────────────────────────────────

func _set_focus(card: Card) -> void:
	if _focused_card == card:
		return
	if _focused_card != null:
		_focused_card.set_hovered(false)
	_focused_card = card
	if _focused_card != null:
		_focused_card.set_hovered(true)

# ── Draw / discard ─────────────────────────────────────────────────────────────

## Draws count cards with a staggered delay between each, animating them into the hand.
func draw_multiple(count: int, stagger_delay: float = 0.12) -> void:
	for draw_index: int in count:
		get_tree().create_timer(stagger_delay * draw_index).timeout.connect(draw)

func draw() -> void:
	if get_child_count() >= MAX_HAND_SIZE:
		return
	var card_data: CardData = null
	if _deck != null:
		card_data = _deck.draw_card()
		if card_data == null:
			return
	_set_focus(null)
	var new_card: Card = CARD.instantiate()
	add_child(new_card)
	if card_data != null:
		new_card.data = card_data
	_update_cards()
	_animate_card_in(new_card)

func discard() -> void:
	if get_child_count() < 1:
		return
	var card: Card = get_child(get_child_count() - 1)
	if _focused_card == card:
		_set_focus(null)
	if _deck != null and card.data != null:
		_deck.discard_card(card.data)
	card.reparent(get_tree().root)
	card.queue_free()
	_update_cards()

# ── Layout ─────────────────────────────────────────────────────────────────────

func _animate_card_in(card: Card) -> void:
	var target_position: Vector2 = card.position
	var target_rotation: float = card.rotation_degrees

	# Start from the bottom-centre of the hand container (mimics drawing from a deck)
	card.position = Vector2(size.x / 2.0 - Card.SIZE.x / 2.0, size.y + Card.SIZE.y * 0.5)
	card.rotation_degrees = 0.0
	card.modulate.a = 0.0

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(card, "position", target_position, 0.32) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "rotation_degrees", target_rotation, 0.32) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "modulate:a", 1.0, 0.18) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)

	# Reflow existing cards smoothly to make room for the new arrival
	_animate_reflow(card)

func _animate_reflow(skip_card: Card) -> void:
	var card_count: int = get_child_count()
	var all_cards_size: float = Card.SIZE.x * card_count + x_sep * (card_count - 1)

	var final_x_sep: float = x_sep
	if all_cards_size > size.x:
		final_x_sep = (size.x - Card.SIZE.x * card_count) / (card_count - 1)
		all_cards_size = size.x

	var left_offset: float = (size.x - all_cards_size) / 2.0

	for card_index: int in card_count:
		var card: Card = get_child(card_index)
		if card == skip_card:
			continue
		var y_multiplier: float = hand_curve.sample(1.0 / (card_count - 1) * card_index) if card_count > 1 else 0.0
		var rot_multiplier: float = rotation_curve.sample(1.0 / (card_count - 1) * card_index) if card_count > 1 else 0.0

		var target_x: float = left_offset + Card.SIZE.x * card_index + final_x_sep * card_index
		var target_y: float = y_min + y_max * y_multiplier

		var reflow_tween: Tween = create_tween().set_parallel(true)
		reflow_tween.tween_property(card, "position", Vector2(target_x, target_y), 0.22) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		reflow_tween.tween_property(card, "rotation_degrees", max_rotation_degrees * rot_multiplier, 0.22) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _update_cards() -> void:
	var card_count: int = get_child_count()
	var all_cards_size: float = Card.SIZE.x * card_count + x_sep * (card_count - 1)

	var final_x_sep: float = x_sep

	# If the total card width exceeds the container, overlap cards to fit
	if all_cards_size > size.x:
		final_x_sep = (size.x - Card.SIZE.x * card_count) / (card_count - 1)
		all_cards_size = size.x

	# Center the card row within the hand container
	var left_offset: float = (size.x - all_cards_size) / 2.0

	_resting_positions.resize(card_count)

	for card_index: int in card_count:
		var card: Card = get_child(card_index)
		var y_multiplier: float = hand_curve.sample(1.0 / (card_count - 1) * card_index) if card_count > 1 else 0.0
		var rot_multiplier: float = rotation_curve.sample(1.0 / (card_count - 1) * card_index) if card_count > 1 else 0.0

		var final_x: float = left_offset + Card.SIZE.x * card_index + final_x_sep * card_index
		var final_y: float = y_min + y_max * y_multiplier

		_resting_positions[card_index] = Vector2(final_x, final_y)
		card.position = Vector2(final_x, final_y)
		card.rotation_degrees = max_rotation_degrees * rot_multiplier
