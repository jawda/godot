class_name ShellGameEvent
extends Control

## Shell game event room.
##
## Tester version: auto-offers the first card in the player's deck.
## Win → duplicate added. Lose → card removed.
## Full card-picker UX to be wired in after visual sign-off.

signal room_completed

# ── Layout constants ───────────────────────────────────────────────────────────

const CUP_SIZE: Vector2    = Vector2(90.0, 150.0)
## Left-edge x position for each of the three cup slots within CupStage.
const SLOT_X: Array[float] = [45.0, 183.0, 323.0]
const CUP_START_Y: float   = 120.0
const LIFT_AMOUNT: float   = 110.0
const BALL_SIZE: float     = 18.0

# ── Shuffle constants ──────────────────────────────────────────────────────────

const SHUFFLE_STEPS: int        = 8
const SWAP_DURATION_SLOW: float = 0.44   # first swap
const SWAP_DURATION_FAST: float = 0.20   # last swap (speeds up mid-sequence)

# ── Node references ────────────────────────────────────────────────────────────

@onready var _offered_label: Label  = $Panel/Contents/Header/Info/Offered
@onready var _cup_stage: Control    = $Panel/Contents/CupSection/CupStage
@onready var _status_label: Label   = $Panel/Contents/StatusSection/Status
@onready var _action_button: Button = $Panel/Contents/Footer/Action
@onready var _card_picker: CardPicker = $CardPicker
@onready var _intro_overlay: Control  = $IntroOverlay
@onready var _accept_button: Button   = $IntroOverlay/Dialog/Contents/Footer/Choices/Accept
@onready var _decline_button: Button  = $IntroOverlay/Dialog/Contents/Footer/Choices/Decline

# ── State ──────────────────────────────────────────────────────────────────────

enum _State { INTRO, SHUFFLING, GUESSING, REVEALING, DONE }

var _state: _State = _State.INTRO

var _cups: Array[Cup] = []
## _cup_slots[cup_node_index] = which slot (0/1/2) that cup currently occupies.
var _cup_slots: Array[int] = [0, 1, 2]
## Which cup node index actually hides the card.
var _card_cup_index: int = 0
var _card_indicator: Label = null
var _ball: Panel = null

var _card_was_chosen: bool = false

var _offered_card_name: String    = ""
var _offered_card_path: String    = ""
var _offered_card_upgrade: bool   = false
var _offered_card_deck_index: int = -1

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_action_button.visible = false
	_action_button.pressed.connect(_on_action_pressed)
	_accept_button.pressed.connect(_on_intro_accepted)
	_decline_button.pressed.connect(_on_intro_declined)
	_setup_cup_stage()

# ── Intro ──────────────────────────────────────────────────────────────────────

func _on_intro_accepted() -> void:
	_intro_overlay.hide()
	var deck_cards: Array[CardData] = _build_deck_card_list()
	if deck_cards.is_empty():
		room_completed.emit()
		return
	_status_label.text = "Choose a card to wager."
	_card_picker.card_chosen.connect(_on_card_chosen, CONNECT_ONE_SHOT)
	_card_picker.open("Choose a card to wager", deck_cards)
	_card_picker.visibility_changed.connect(_on_picker_closed, CONNECT_ONE_SHOT)

func _on_intro_declined() -> void:
	room_completed.emit()

# ── Card selection ─────────────────────────────────────────────────────────────

func _build_deck_card_list() -> Array[CardData]:
	var run: RunSaveData = RunState.active_run
	var result: Array[CardData] = []
	if run == null:
		return result
	for path: String in run.deck_card_paths:
		var card: CardData = load(path) as CardData
		if card != null:
			result.append(card)
	return result

func _on_card_chosen(card: CardData) -> void:
	_card_was_chosen = true
	_configure_offered_card(card)
	_play_intro()

func _on_picker_closed() -> void:
	if not _card_picker.visible and not _card_was_chosen:
		room_completed.emit()

func _configure_offered_card(card: CardData) -> void:
	var run: RunSaveData = RunState.active_run
	if run == null:
		return
	_offered_card_name       = card.card_name
	_offered_card_path       = card.resource_path
	_offered_card_deck_index = run.deck_card_paths.find(card.resource_path)
	_offered_card_upgrade    = _offered_card_deck_index >= 0 \
			and _offered_card_deck_index < run.deck_card_upgrades.size() \
			and run.deck_card_upgrades[_offered_card_deck_index]
	if _card_indicator != null:
		_card_indicator.text = _offered_card_name

# ── Cup stage setup ────────────────────────────────────────────────────────────

func _setup_cup_stage() -> void:
	_card_cup_index = randi() % 3
	_cup_slots      = [0, 1, 2]

	for cup_node_index: int in 3:
		var cup: Cup = Cup.new()
		cup.cup_index          = cup_node_index
		cup.custom_minimum_size = CUP_SIZE
		cup.cup_clicked.connect(_on_cup_clicked)
		_cup_stage.add_child(cup)
		cup.size     = CUP_SIZE
		cup.position = Vector2(SLOT_X[cup_node_index], CUP_START_Y)
		_cups.append(cup)

	_card_indicator = Label.new()
	_card_indicator.text                   = _offered_card_name
	_card_indicator.horizontal_alignment   = HORIZONTAL_ALIGNMENT_CENTER
	_card_indicator.add_theme_font_size_override("font_size", 11)
	_card_indicator.add_theme_color_override("font_color", Color(0.90, 0.78, 0.18, 1.0))
	_card_indicator.custom_minimum_size    = Vector2(CUP_SIZE.x, 20.0)
	_card_indicator.modulate.a             = 0.0
	_cup_stage.add_child(_card_indicator)

	var ball_style: StyleBoxFlat = StyleBoxFlat.new()
	ball_style.bg_color = Color(0.92, 0.80, 0.22, 1.0)
	ball_style.set_corner_radius_all(int(BALL_SIZE * 0.5))
	_ball = Panel.new()
	_ball.add_theme_stylebox_override("panel", ball_style)
	_ball.custom_minimum_size = Vector2(BALL_SIZE, BALL_SIZE)
	_ball.modulate.a = 0.0
	_cup_stage.add_child(_ball)

# ── Intro animation ────────────────────────────────────────────────────────────

func _play_intro() -> void:
	var upgrade_tag: String = " (Upgraded)" if _offered_card_upgrade else ""
	_offered_label.text = "Offering: %s%s" % [_offered_card_name, upgrade_tag]
	_status_label.text  = "Watch where the card goes..."
	await _play_ball_drop()
	_set_state(_State.INTRO)

func _play_ball_drop() -> void:
	var cup_x: float  = SLOT_X[_card_cup_index]
	var ball_x: float = cup_x + CUP_SIZE.x * 0.5 - BALL_SIZE * 0.5
	var rim_y: float  = CUP_START_Y + 5.0
	var sink_y: float = CUP_START_Y + 38.0

	_ball.size     = Vector2(BALL_SIZE, BALL_SIZE)
	_ball.position = Vector2(ball_x, CUP_START_Y - 65.0)

	# Drop from above and bounce into the cup opening
	var tween_drop: Tween = create_tween().set_parallel(true)
	tween_drop.tween_property(_ball, "modulate:a", 1.0, 0.10)
	tween_drop.tween_property(_ball, "position:y", rim_y, 0.45) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	await tween_drop.finished

	# Pause so the player can register which cup the ball is in
	await get_tree().create_timer(0.55).timeout

	# Sink into the cup body and fade out
	var tween_sink: Tween = create_tween().set_parallel(true)
	tween_sink.tween_property(_ball, "position:y", sink_y, 0.22) \
			.set_ease(Tween.EASE_IN)
	tween_sink.tween_property(_ball, "modulate:a", 0.0, 0.20)
	await tween_sink.finished

# ── State machine ──────────────────────────────────────────────────────────────

func _set_state(new_state: _State) -> void:
	_state = new_state
	match new_state:
		_State.INTRO:
			var upgrade_tag: String = " (Upgraded)" if _offered_card_upgrade else ""
			_offered_label.text = "Offering: %s%s" % [_offered_card_name, upgrade_tag]
			_status_label.text  = "The figure sets your card beneath one cup and begins."
			_action_button.text     = "Begin"
			_action_button.disabled = false
			_action_button.visible  = true
		_State.SHUFFLING:
			_status_label.text     = "Watch carefully..."
			_action_button.visible = false
			_run_shuffle()
		_State.GUESSING:
			_status_label.text = "Which cup hides your card?"
			_action_button.visible = false
			for cup: Cup in _cups:
				cup.is_clickable = true
		_State.REVEALING:
			_action_button.visible = false
		_State.DONE:
			_action_button.text     = "Continue"
			_action_button.disabled = false
			_action_button.visible  = true

func _on_action_pressed() -> void:
	match _state:
		_State.INTRO:
			_set_state(_State.SHUFFLING)
		_State.DONE:
			room_completed.emit()

# ── Shuffle sequence ───────────────────────────────────────────────────────────

func _run_shuffle() -> void:
	var sequence: Array[Vector2i] = []
	var last_swap: Vector2i = Vector2i(-1, -1)
	for _step: int in SHUFFLE_STEPS:
		var swap: Vector2i = _pick_random_swap(last_swap)
		sequence.append(swap)
		last_swap = swap
	_execute_swap_sequence(sequence, 0)

func _pick_random_swap(avoid: Vector2i) -> Vector2i:
	var options: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]
	if avoid.x >= 0:
		options.erase(avoid)
	return options[randi() % options.size()]

func _execute_swap_sequence(sequence: Array[Vector2i], step: int) -> void:
	if step >= sequence.size():
		_set_state(_State.GUESSING)
		return
	var progress: float = float(step) / float(maxi(sequence.size() - 1, 1))
	var duration: float = lerpf(SWAP_DURATION_SLOW, SWAP_DURATION_FAST, progress)
	await _animate_swap(sequence[step].x, sequence[step].y, duration)
	_execute_swap_sequence(sequence, step + 1)

func _animate_swap(slot_a: int, slot_b: int, duration: float) -> void:
	var cup_in_a: int = _cup_slots.find(slot_a)
	var cup_in_b: int = _cup_slots.find(slot_b)

	_cup_slots[cup_in_a] = slot_b
	_cup_slots[cup_in_b] = slot_a

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_cups[cup_in_a], "position:x", SLOT_X[slot_b], duration) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_cups[cup_in_b], "position:x", SLOT_X[slot_a], duration) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

# ── Reveal ─────────────────────────────────────────────────────────────────────

func _on_cup_clicked(cup_node_index: int) -> void:
	if _state != _State.GUESSING:
		return
	for cup: Cup in _cups:
		cup.is_clickable = false
	_set_state(_State.REVEALING)
	_reveal_cups(cup_node_index)

func _reveal_cups(chosen_cup_index: int) -> void:
	# Place indicator under whichever slot the card cup currently occupies
	var card_cup_x: float = _cups[_card_cup_index].position.x
	_card_indicator.position = Vector2(card_cup_x, CUP_START_Y + CUP_SIZE.y + 8.0)

	var tween: Tween = create_tween().set_parallel(true)
	for cup: Cup in _cups:
		tween.tween_property(cup, "position:y", CUP_START_Y - LIFT_AMOUNT, 0.50) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_card_indicator, "modulate:a", 1.0, 0.35).set_delay(0.25)
	await tween.finished

	var won: bool = (chosen_cup_index == _card_cup_index)
	_apply_result(won)

	if won:
		_status_label.text = "Your card... and a second copy. Well played."
		_status_label.add_theme_color_override("font_color", Color(0.45, 0.88, 0.50, 1.0))
	else:
		_status_label.text = "The figure pockets your card and walks away."
		_status_label.add_theme_color_override("font_color", Color(0.90, 0.35, 0.35, 1.0))

	_set_state(_State.DONE)

# ── Apply win / lose ───────────────────────────────────────────────────────────

func _apply_result(won: bool) -> void:
	var run: RunSaveData = RunState.active_run
	if run == null or _offered_card_deck_index < 0:
		return
	if won:
		run.deck_card_paths.append(_offered_card_path)
		run.deck_card_upgrades.append(_offered_card_upgrade)
	else:
		run.deck_card_paths.remove_at(_offered_card_deck_index)
		if _offered_card_deck_index < run.deck_card_upgrades.size():
			run.deck_card_upgrades.remove_at(_offered_card_deck_index)
	SaveManager.save()
