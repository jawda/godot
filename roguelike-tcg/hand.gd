class_name Hand
extends ColorRect

const CARD: PackedScene = preload("res://cards/card.tscn")
const MAX_HAND_SIZE: int = 10
## How many pixels above its resting position a card must be dragged to trigger play on release.
const DRAG_PLAY_THRESHOLD: float = -80.0

@export var hand_curve: Curve
@export var rotation_curve: Curve

@export var max_rotation_degrees: int = 5
@export var x_sep: int = -10
@export var y_min: int = 0
@export var y_max: int = -35

## Emitted when the focused card is clicked or confirmed via controller.
signal card_play_requested(card_data: CardData)
## Emitted when a card is released from drag above the play threshold.
## Carries the global mouse position so Battlefield can hit-test enemies.
signal card_drag_play_requested(card_data: CardData, release_pos: Vector2)
## Emitted each time a card is successfully drawn from the deck.
signal card_drawn

var _deck: Deck = null
var _focused_card: Card = null
var _drag_card: Card = null
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_ready: bool = false
var _input_enabled: bool = true

# Resting positions are the TARGET layout positions — updated immediately when
# the layout changes, even while cards are still animating there.
# Hover detection uses these so hit rects are always accurate.
var _resting_positions: Array[Vector2] = []

# One stored tween per card so old reflow tweens can be killed before
# starting a new one for the same card.
var _reflow_tweens: Dictionary = {}

func set_deck(deck: Deck) -> void:
	_deck = deck

# ── Input ──────────────────────────────────────────────────────────────────────

## Disables all card input. Used by Battlefield while targeting is active so
## enemy clicks are not intercepted by the hand.
func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled and _drag_card != null:
		var card: Card = _drag_card
		_drag_card = null
		card.modulate = Color.WHITE
		card.z_index = 0
		_drag_ready = false
		_set_focus(null)

func _input(event: InputEvent) -> void:
	if not _input_enabled:
		return
	if event is InputEventMouseMotion:
		var mouse_pos: Vector2 = get_local_mouse_position()
		if _drag_card != null:
			_update_drag(mouse_pos)
		elif Rect2(Vector2.ZERO, size).has_point(mouse_pos):
			_set_focus(_card_at_position(mouse_pos))
		else:
			_set_focus(null)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _focused_card != null and _focused_card.data != null:
				_start_drag(_focused_card, get_local_mouse_position())
				get_viewport().set_input_as_handled()
		else:
			if _drag_card != null:
				_resolve_drag()
				get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if _focused_card != null and _focused_card.data != null:
			card_play_requested.emit(_focused_card.data)
			get_viewport().set_input_as_handled()
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

# ── Drag ───────────────────────────────────────────────────────────────────────

func _start_drag(card: Card, mouse_pos: Vector2) -> void:
	_drag_card = card
	_drag_offset = card.position - mouse_pos
	_drag_ready = false
	card.cancel_animations()
	card.rotation_degrees = 0.0
	card.z_index = 20

func _update_drag(mouse_pos: Vector2) -> void:
	var card_index: int = _drag_card.get_index()
	if card_index >= _resting_positions.size():
		return
	var new_pos: Vector2 = mouse_pos + _drag_offset
	_drag_card.position = new_pos
	var was_ready: bool = _drag_ready
	_drag_ready = (new_pos.y - _resting_positions[card_index].y) < DRAG_PLAY_THRESHOLD
	if _drag_ready != was_ready:
		_drag_card.modulate = Color(1.4, 1.3, 0.7) if _drag_ready else Color.WHITE

## Snaps a card with the given data back to its resting position after a drag
## that did not result in a play (missed target, not enough energy, etc.).
## The card stays in the hand — this only restores its visual position.
func return_dragged_card(card_data: CardData) -> void:
	for card_index: int in get_child_count():
		var card: Card = get_child(card_index) as Card
		if card == null or card.data != card_data:
			continue
		if card_index >= _resting_positions.size():
			return
		var layout_rotations: Array[float] = (_calc_layout() as Array)[1]
		var snap_tween: Tween = create_tween().set_parallel(true)
		snap_tween.tween_property(card, "position", _resting_positions[card_index], 0.3) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		snap_tween.tween_property(card, "rotation_degrees", layout_rotations[card_index], 0.3) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		return

func _resolve_drag() -> void:
	var card: Card = _drag_card
	_drag_card = null
	card.modulate = Color.WHITE
	card.z_index = 0
	if _drag_ready and card.data != null:
		_drag_ready = false
		_set_focus(null)
		card_drag_play_requested.emit(card.data, get_global_mouse_position())
	else:
		_drag_ready = false
		var card_index: int = card.get_index()
		var layout: Array = _calc_layout()
		var positions: Array[Vector2] = layout[0]
		var rotations: Array[float] = layout[1]
		if card_index < positions.size():
			var snap_tween: Tween = create_tween().set_parallel(true)
			snap_tween.tween_property(card, "position", positions[card_index], 0.3) \
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			snap_tween.tween_property(card, "rotation_degrees", rotations[card_index], 0.3) \
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		_set_focus(null)

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
		card_drawn.emit()
	_set_focus(null)
	var new_card: Card = CARD.instantiate()
	add_child(new_card)
	if card_data != null:
		new_card.data = card_data
	# Snap resting positions first so hit detection is correct immediately,
	# then animate cards to those positions.
	_refresh_resting_positions()
	_animate_card_in(new_card)

func discard() -> void:
	if get_child_count() < 1:
		return
	var card: Card = get_child(get_child_count() - 1)
	if _focused_card == card:
		_set_focus(null)
	if _deck != null and card.data != null:
		_deck.discard_card(card.data)
	_reflow_tweens.erase(card)
	remove_child(card)
	card.queue_free()
	_refresh_resting_positions()

func discard_all() -> void:
	_set_focus(null)
	for card_index: int in range(get_child_count() - 1, -1, -1):
		var card: Card = get_child(card_index) as Card
		if card == null:
			continue
		if _deck != null and card.data != null:
			_deck.discard_card(card.data)
		_reflow_tweens.erase(card)
		remove_child(card)
		card.queue_free()
	_resting_positions.clear()

## Finds and exiles the first Card node whose data reference matches card_data.
## Used for played Power/Blessing cards — they leave the hand and cannot be
## redrawn this combat, but return to the deck at the start of the next combat.
func exile_specific_data(card_data: CardData) -> void:
	for card_index: int in get_child_count():
		var card: Card = get_child(card_index) as Card
		if card == null or card.data != card_data:
			continue
		if _focused_card == card:
			_set_focus(null)
		if _deck != null:
			_deck.exile_card(card_data)
		_reflow_tweens.erase(card)
		if card_index < _resting_positions.size():
			_resting_positions[card_index] = Vector2(-9999.0, -9999.0)
		_finish_discard_animation(card)
		return

## Finds and discards the first Card node whose data reference matches card_data.
func discard_specific_data(card_data: CardData) -> void:
	for card_index: int in get_child_count():
		var card: Card = get_child(card_index) as Card
		if card == null or card.data != card_data:
			continue
		if _focused_card == card:
			_set_focus(null)
		if _deck != null:
			_deck.discard_card(card_data)
		_reflow_tweens.erase(card)
		# Push the resting position offscreen so hover detection ignores this card
		# while it animates. The child stays in the tree so it remains visible.
		if card_index < _resting_positions.size():
			_resting_positions[card_index] = Vector2(-9999.0, -9999.0)
		_finish_discard_animation(card)
		return

## Plays the discard animation then removes the card and reflows the hand.
## Called without await — runs asynchronously in the background.
func _finish_discard_animation(card: Card) -> void:
	await card.play_discard()
	if is_instance_valid(card):
		remove_child(card)
		card.queue_free()
	_refresh_resting_positions()
	_animate_reflow(null)

## Adds a card directly into the hand without drawing from the deck.
func add_card_to_hand(card_data: CardData) -> void:
	if get_child_count() >= MAX_HAND_SIZE:
		return
	_set_focus(null)
	var new_card: Card = CARD.instantiate()
	add_child(new_card)
	new_card.data = card_data
	_refresh_resting_positions()
	_animate_card_in(new_card)

# ── Layout ─────────────────────────────────────────────────────────────────────

## Calculates the target position and rotation for each card given the current
## child count. Returns parallel arrays: positions and rotation_degrees.
func _calc_layout() -> Array:
	var card_count: int = get_child_count()
	var positions: Array[Vector2] = []
	var rotations: Array[float] = []
	positions.resize(card_count)
	rotations.resize(card_count)

	if card_count == 0:
		return [positions, rotations]

	var all_cards_size: float = Card.SIZE.x * card_count + x_sep * (card_count - 1)
	var final_x_sep: float = x_sep
	if all_cards_size > size.x:
		final_x_sep = (size.x - Card.SIZE.x * card_count) / float(card_count - 1)
		all_cards_size = size.x
	var left_offset: float = (size.x - all_cards_size) / 2.0

	for card_index: int in card_count:
		var layout_fraction: float = (1.0 / (card_count - 1) * card_index) if card_count > 1 else 0.0
		var final_x: float = left_offset + Card.SIZE.x * card_index + final_x_sep * card_index
		var final_y: float = y_min + y_max * hand_curve.sample(layout_fraction)
		positions[card_index] = Vector2(final_x, final_y)
		rotations[card_index] = max_rotation_degrees * rotation_curve.sample(layout_fraction)

	return [positions, rotations]

## Updates _resting_positions to the current target layout and snaps card transforms.
## Use after structural changes (child added/removed) when animation isn't needed.
func _refresh_resting_positions() -> void:
	var layout: Array = _calc_layout()
	var positions: Array[Vector2] = layout[0]
	var rotations: Array[float] = layout[1]
	_resting_positions.resize(positions.size())
	for card_index: int in positions.size():
		_resting_positions[card_index] = positions[card_index]
		var card: Card = get_child(card_index)
		card.position = positions[card_index]
		card.rotation_degrees = rotations[card_index]

func _animate_card_in(card: Card) -> void:
	var target_pos: Vector2 = card.position
	var target_rot: float = card.rotation_degrees

	card.position = Vector2(size.x / 2.0 - Card.SIZE.x / 2.0, size.y + Card.SIZE.y * 0.5)
	card.rotation_degrees = 0.0
	card.modulate.a = 0.0

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(card, "position", target_pos, 0.32) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "rotation_degrees", target_rot, 0.32) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "modulate:a", 1.0, 0.18) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)

	_animate_reflow(card)

## Smoothly moves all cards (except skip_card) to their target layout positions.
## Also updates _resting_positions immediately so hit detection is accurate
## during the animation, not just after it finishes.
func _animate_reflow(skip_card: Card) -> void:
	var layout: Array = _calc_layout()
	var positions: Array[Vector2] = layout[0]
	var rotations: Array[float] = layout[1]

	# Update resting positions to targets right away — hit detection is based on
	# where cards are heading, not where they currently are.
	_resting_positions.resize(positions.size())
	for card_index: int in positions.size():
		_resting_positions[card_index] = positions[card_index]

	for card_index: int in get_child_count():
		var card: Card = get_child(card_index)
		if card == skip_card:
			continue
		# Kill any in-flight reflow tween for this card before starting a new one.
		if _reflow_tweens.has(card) and is_instance_valid(_reflow_tweens[card]):
			_reflow_tweens[card].kill()
		var reflow_tween: Tween = create_tween().set_parallel(true)
		_reflow_tweens[card] = reflow_tween
		reflow_tween.tween_property(card, "position", positions[card_index], 0.22) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		reflow_tween.tween_property(card, "rotation_degrees", rotations[card_index], 0.22) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
