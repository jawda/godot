class_name Battlefield
extends Control

# ── Scene configuration ──────────────────────────────────────────────────────────

@export var player_data: PlayerData
@export var enemy_data_list: Array[EnemyData] = []

# ── Preloads ─────────────────────────────────────────────────────────────────────

const ENEMY_SCENE: PackedScene = preload("res://enemy/enemy.tscn")

## Maps SPECIAL action param strings to the EnemyData resource they spawn.
const SUMMON_LOOKUP: Dictionary = {
	"summon_skeleton": "res://enemy/data/restless_skeleton.tres",
}

const TARGET_HIGHLIGHT: Color = Color(1.4, 1.1, 1.1, 1.0)
const TARGET_DIM: Color       = Color(0.5, 0.5, 0.5, 1.0)
const PIP_FILLED: Color       = Color(0.9, 0.72, 0.18, 1.0)
const PIP_EMPTY: Color        = Color(0.12, 0.08, 0.06, 1.0)
const PIP_BORDER: Color       = Color(0.55, 0.42, 0.10, 0.8)

# ── Node references ───────────────────────────────────────────────────────────────

@onready var _hand_area: Hand                = $MainLayout/HandArea
@onready var _enemy_row: HBoxContainer       = $MainLayout/BattleArea/EnemyRow
@onready var _end_turn_button: Button        = $MainLayout/BattleArea/PlayerSection/HUD/EndTurnButton
@onready var _draw_pile_label: Label         = $MainLayout/BattleArea/PlayerSection/HUD/PileCounters/DrawPileLabel
@onready var _discard_pile_label: Label      = $MainLayout/BattleArea/PlayerSection/HUD/PileCounters/DiscardPileLabel
@onready var _player_stats_box: VBoxContainer = $MainLayout/BattleArea/PlayerSection/PlayerArea/PlayerStatsBox
@onready var _player_hp_label: Label         = $MainLayout/BattleArea/PlayerSection/PlayerArea/PlayerStatsBox/PlayerHPLabel
@onready var _player_health_bar: ProgressBar = $MainLayout/BattleArea/PlayerSection/PlayerArea/PlayerStatsBox/PlayerHealthBar
@onready var _player_block_label: Label      = $MainLayout/BattleArea/PlayerSection/PlayerArea/PlayerStatsBox/PlayerBlockLabel
## Sourced from HUD but reparented to player stats box in _setup_combat.
@onready var _energy_label: Label            = $MainLayout/BattleArea/PlayerSection/HUD/EnergyLabel

# ── Runtime ───────────────────────────────────────────────────────────────────────

var _combat_manager: CombatManager = null
var _deck: Deck = null
var _enemies: Array[Enemy] = []
var _pending_card: CardData = null
var _energy_pips: Array[Panel] = []
var _combat_over: bool = false

var _deck_viewer: DeckViewer = null
var _btn_full_deck: Button   = null
var _btn_draw_pile: Button   = null
var _btn_discard: Button     = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	if player_data == null or enemy_data_list.is_empty():
		return
	_setup_combat()

# ── Setup ─────────────────────────────────────────────────────────────────────────

func _setup_combat() -> void:
	_deck = Deck.new()
	_deck.load_from_data(player_data.starter_deck)
	_hand_area.set_deck(_deck)

	for enemy_data: EnemyData in enemy_data_list:
		var enemy_node: Enemy = ENEMY_SCENE.instantiate() as Enemy
		_enemy_row.add_child(enemy_node)
		enemy_node.setup(enemy_data)
		enemy_node.clicked.connect(_on_enemy_clicked)
		_enemies.append(enemy_node)

	_combat_manager = CombatManager.new()
	add_child(_combat_manager)
	_combat_manager.setup(player_data, _hand_area, _deck, _enemies)

	_combat_manager.player_hp_changed.connect(_on_player_hp_changed)
	_combat_manager.player_block_changed.connect(_on_player_block_changed)
	_combat_manager.player_energy_changed.connect(_on_player_energy_changed)
	_combat_manager.draw_pile_changed.connect(_on_draw_pile_changed)
	_combat_manager.discard_pile_changed.connect(_on_discard_pile_changed)
	_combat_manager.special_action_triggered.connect(_on_special_action_triggered)
	_combat_manager.enemy_died.connect(_on_enemy_died)
	_combat_manager.player_turn_began.connect(_on_player_turn_began)
	_combat_manager.enemy_turn_began.connect(_on_enemy_turn_began)
	_combat_manager.combat_ended.connect(_on_combat_ended)

	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_hand_area.card_play_requested.connect(_on_card_play_requested)

	_player_health_bar.max_value = player_data.base_max_health + \
			player_data.constitution * CombatPlayer.HP_PER_CONSTITUTION

	# Move energy label from HUD to the player stats box
	_energy_label.reparent(_player_stats_box)
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	_setup_deck_viewer()
	_btn_full_deck.text = "Deck  %d" % _deck.total_count()
	_combat_manager.start_combat()

# ── Deck viewer setup ─────────────────────────────────────────────────────────

func _setup_deck_viewer() -> void:
	# Viewer overlay — sits above the battlefield, below the combat-result overlay
	_deck_viewer = DeckViewer.new()
	add_child(_deck_viewer)

	# Add buttons directly to the battlefield root so they float over everything.
	# Positioning is deferred because size is not finalised during _ready().
	_btn_full_deck = _make_pile_button("Deck")
	_btn_full_deck.pressed.connect(_on_btn_full_deck_pressed)
	add_child(_btn_full_deck)

	_btn_draw_pile = _make_pile_button("Draw")
	_btn_draw_pile.pressed.connect(_on_btn_draw_pile_pressed)
	add_child(_btn_draw_pile)

	_btn_discard = _make_pile_button("Discard")
	_btn_discard.pressed.connect(_on_btn_discard_pressed)
	add_child(_btn_discard)

	# Re-position whenever the window resizes, and once after layout settles.
	resized.connect(_reposition_pile_buttons)
	_reposition_pile_buttons.call_deferred()

func _reposition_pile_buttons() -> void:
	var w: float = size.x
	var h: float = size.y
	var btn_w: float = 108.0
	var btn_h: float = 32.0
	var margin: float = 12.0

	_btn_draw_pile.position = Vector2(margin, h - btn_h - margin)
	_btn_draw_pile.size     = Vector2(btn_w, btn_h)

	_btn_full_deck.position = Vector2(w - btn_w - margin, margin)
	_btn_full_deck.size     = Vector2(btn_w, btn_h)

	_btn_discard.position   = Vector2(w - btn_w - margin, h - btn_h - margin)
	_btn_discard.size       = Vector2(btn_w, btn_h)

func _make_pile_button(label: String) -> Button:
	var btn: Button = Button.new()
	btn.text = label
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color     = Color(0.07, 0.04, 0.12, 0.88)
	style.set_border_width_all(1)
	style.border_color = Color(0.44, 0.22, 0.66, 0.85)
	style.set_corner_radius_all(5)
	style.content_margin_left   = 10.0
	style.content_margin_right  = 10.0
	style.content_margin_top    = 6.0
	style.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override("normal", style)
	var hover_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover_style.bg_color     = Color(0.12, 0.07, 0.20, 0.95)
	hover_style.border_color = Color(0.65, 0.35, 0.90)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_color_override("font_color", Color(0.78, 0.68, 0.92))
	btn.add_theme_font_size_override("font_size", 12)
	return btn

func _on_btn_full_deck_pressed() -> void:
	var cards: Array[CardData] = _deck.get_all_cards()
	cards.sort_custom(func(a: CardData, b: CardData) -> bool:
		if a.card_type != b.card_type:
			return a.card_type < b.card_type
		return a.card_name < b.card_name)
	_deck_viewer.open("Full Deck", cards)
	_btn_full_deck.text = "Deck  %d" % _deck.total_count()

func _on_btn_draw_pile_pressed() -> void:
	_deck_viewer.open("Draw Pile", _deck.get_draw_pile())

func _on_btn_discard_pressed() -> void:
	_deck_viewer.open("Discard Pile", _deck.get_discard_pile())

# ── Input ─────────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _pending_card == null:
		return
	if _deck_viewer != null and _deck_viewer.visible:
		return
	var cancel: bool = (event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed) \
			or event.is_action_pressed("ui_cancel")
	if cancel:
		_cancel_targeting()
		get_viewport().set_input_as_handled()

# ── Card play / targeting ─────────────────────────────────────────────────────────

func _on_card_play_requested(card_data: CardData) -> void:
	if not _combat_manager.can_play(card_data):
		_show_toast("Not enough energy")
		return
	if _needs_enemy_target(card_data):
		_pending_card = card_data
		_enter_targeting_mode()
	else:
		_combat_manager.play_card(card_data, null)

func _on_enemy_clicked(enemy: Enemy) -> void:
	if _pending_card == null:
		return
	if enemy.is_dead():
		return
	var card: CardData = _pending_card
	_exit_targeting_mode()
	_combat_manager.play_card(card, enemy)

func _cancel_targeting() -> void:
	_exit_targeting_mode()

func _needs_enemy_target(card_data: CardData) -> bool:
	for effect: CardEffect in card_data.effects:
		if effect.target == CardEffect.Target.ENEMY:
			return true
	return false

# ── Targeting visuals ─────────────────────────────────────────────────────────────

func _enter_targeting_mode() -> void:
	_hand_area.set_input_enabled(false)
	for enemy: Enemy in _enemies:
		if enemy.is_dead():
			enemy.modulate = TARGET_DIM
			enemy.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		else:
			enemy.modulate = TARGET_HIGHLIGHT
			enemy.mouse_default_cursor_shape = Control.CURSOR_CROSS

func _exit_targeting_mode() -> void:
	_pending_card = null
	_hand_area.set_input_enabled(true)
	for enemy: Enemy in _enemies:
		enemy.modulate = Color.WHITE
		enemy.mouse_default_cursor_shape = Control.CURSOR_ARROW

# ── End turn ──────────────────────────────────────────────────────────────────────

func _on_end_turn_pressed() -> void:
	if _pending_card != null:
		_cancel_targeting()
	_combat_manager.end_player_turn()

# ── UI signal handlers ────────────────────────────────────────────────────────────

func _on_player_hp_changed(current: int, max_val: int) -> void:
	_player_hp_label.text = "HP: %d / %d" % [current, max_val]
	_player_health_bar.max_value = max_val
	_player_health_bar.value = current

func _on_player_block_changed(block: int) -> void:
	_player_block_label.text = "Block: %d" % block
	_player_block_label.visible = block > 0

func _on_player_energy_changed(current: int, max_val: int) -> void:
	if _combat_over:
		return
	_energy_label.text = "Energy: %d / %d" % [current, max_val]
	_ensure_energy_pips(max_val)
	_refresh_energy_pips(current)

func _on_draw_pile_changed(count: int) -> void:
	_draw_pile_label.text = "Draw: %d" % count
	if _btn_draw_pile:
		_btn_draw_pile.text = "Draw  %d" % count

func _on_discard_pile_changed(count: int) -> void:
	_discard_pile_label.text = "Discard: %d" % count
	if _btn_discard:
		_btn_discard.text = "Discard  %d" % count

func _on_special_action_triggered(param: String) -> void:
	if not SUMMON_LOOKUP.has(param):
		return
	var enemy_data: EnemyData = load(SUMMON_LOOKUP[param]) as EnemyData
	if enemy_data == null:
		return
	var enemy_node: Enemy = ENEMY_SCENE.instantiate() as Enemy
	_enemy_row.add_child(enemy_node)
	enemy_node.setup(enemy_data)
	enemy_node.clicked.connect(_on_enemy_clicked)
	_enemies.append(enemy_node)
	_combat_manager.add_enemy(enemy_node)

func _on_enemy_died(enemy_index: int) -> void:
	var enemy: Enemy = _enemies[enemy_index]
	var tween: Tween = enemy.create_tween()
	tween.tween_property(enemy, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_IN)
	await tween.finished
	enemy.hide()
	enemy.modulate.a = 1.0  # reset alpha so it doesn't stay invisible if ever reused

func _on_player_turn_began(_energy: int, _max_energy: int) -> void:
	_end_turn_button.disabled = false

func _on_enemy_turn_began() -> void:
	_end_turn_button.disabled = true

func _on_combat_ended(victory: bool) -> void:
	_combat_over = true
	_end_turn_button.disabled = true
	_exit_targeting_mode()
	_hand_area.discard_all()
	# Give the death animation time to finish, then show result and clean up
	await get_tree().create_timer(0.5).timeout
	_show_combat_result(victory)
	_cleanup_enemies()

func _show_combat_result(victory: bool) -> void:
	var overlay: Control = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.modulate.a = 0.0
	overlay.add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.03, 0.12, 0.97)
	style.set_corner_radius_all(12)
	style.set_border_width_all(2)
	style.border_color = Color(0.55, 0.28, 0.85) if victory else Color(0.72, 0.14, 0.14)
	style.content_margin_left   = 60.0
	style.content_margin_right  = 60.0
	style.content_margin_top    = 36.0
	style.content_margin_bottom = 36.0
	panel.add_theme_stylebox_override("panel", style)
	panel.modulate.a = 0.0
	center.add_child(panel)

	var label: Label = Label.new()
	label.text = "Victory!" if victory else "Defeated."
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color",
			Color(0.95, 0.78, 0.18) if victory else Color(0.92, 0.32, 0.32))
	panel.add_child(label)

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(bg, "modulate:a", 1.0, 0.35)
	tween.tween_property(panel, "modulate:a", 1.0, 0.35).set_delay(0.1)

func _cleanup_enemies() -> void:
	for enemy: Enemy in _enemies:
		enemy.queue_free()
	_enemies.clear()

# ── Energy pips ───────────────────────────────────────────────────────────────────

func _ensure_energy_pips(max_energy: int) -> void:
	if not _energy_pips.is_empty():
		return
	var pip_row: HBoxContainer = HBoxContainer.new()
	pip_row.add_theme_constant_override("separation", 5)
	_player_stats_box.add_child(pip_row)
	for _i: int in max_energy:
		var pip: Panel = Panel.new()
		pip.custom_minimum_size = Vector2(16, 16)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.set_border_width_all(1)
		style.border_color = PIP_BORDER
		pip.add_theme_stylebox_override("panel", style)
		pip_row.add_child(pip)
		_energy_pips.append(pip)

func _refresh_energy_pips(current_energy: int) -> void:
	for i: int in _energy_pips.size():
		var style: StyleBoxFlat = _energy_pips[i].get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.bg_color = PIP_FILLED if i < current_energy else PIP_EMPTY

# ── Toast notifications ───────────────────────────────────────────────────────────

func _show_toast(message: String) -> void:
	var panel: PanelContainer = PanelContainer.new()
	var label: Label = Label.new()
	label.text = message
	panel.add_child(label)
	add_child(panel)

	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.04, 0.16, 0.92)
	bg.set_corner_radius_all(6)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.75, 0.2, 0.2, 0.9)
	panel.add_theme_stylebox_override("panel", bg)
	label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))

	# Wait one frame so the panel has a valid size before positioning
	await get_tree().process_frame
	panel.position = Vector2(
		size.x * 0.5 - panel.size.x * 0.5,
		size.y * 0.58
	)

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_interval(0.8)
	tween.tween_property(panel, "position:y", panel.position.y - 28.0, 0.5) \
			.set_delay(0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(panel, "modulate:a", 0.0, 0.45) \
			.set_delay(0.8)
	await tween.finished
	panel.queue_free()
