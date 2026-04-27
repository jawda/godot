class_name Battlefield
extends Control

## Emitted after the player dismisses the combat result overlay.
## victory = true → won the fight; false → player was defeated.
signal combat_completed(victory: bool)

# ── Scene configuration ────────────────────────────────────────────────────────

@export var player_data: PlayerData
@export var enemy_data_list: Array[EnemyData] = []
## Set by FloorLoop before entering the scene tree. Determines the reward rarity pool.
@export var room_type: RoomData.RoomType = RoomData.RoomType.COMBAT

# ── Preloads ───────────────────────────────────────────────────────────────────

const ENEMY_SCENE: PackedScene = preload("res://enemy/enemy.tscn")

## Size of the PlayerVisualSlot Control in the scene (must match custom_minimum_size).
const VISUAL_SLOT_SIZE: Vector2 = Vector2(220, 260)
## Native size of one sprite frame — used to scale the visual to fit the slot.
const VISUAL_FRAME_SIZE: Vector2 = Vector2(300, 270)

## Maps SPECIAL action param strings to the EnemyData resource they spawn.
const SUMMON_LOOKUP: Dictionary = {
	"summon_skeleton": "res://enemy/data/restless_skeleton.tres",
}

const TARGET_HIGHLIGHT: Color = Color(1.4, 1.1, 1.1, 1.0)
const TARGET_DIM: Color       = Color(0.5, 0.5, 0.5, 1.0)
const PIP_FILLED: Color       = Color(0.9, 0.72, 0.18, 1.0)
const PIP_EMPTY: Color        = Color(0.12, 0.08, 0.06, 1.0)
const PIP_BORDER: Color       = Color(0.55, 0.42, 0.10, 0.8)

## Gold drop range [min, max] per enemy tier. Summons are included.
const GOLD_RANGE_BY_TIER: Dictionary = {
	EnemyData.Tier.MINION:    Vector2i(8,  14),
	EnemyData.Tier.COMMANDER: Vector2i(14, 22),
	EnemyData.Tier.ELITE:     Vector2i(25, 40),
	EnemyData.Tier.BOSS:      Vector2i(45, 65),
}

# ── Node references ────────────────────────────────────────────────────────────

@onready var _hand_area: Hand                  = $MainLayout/HandArea
@onready var _enemy_row: HBoxContainer         = $MainLayout/BattleArea/EnemyRow
@onready var _end_turn_button: Button          = $MainLayout/BattleArea/PlayerSection/HUD/EndTurnButton
@onready var _draw_pile_label: Label           = $MainLayout/BattleArea/PlayerSection/HUD/PileCounters/DrawPileLabel
@onready var _discard_pile_label: Label        = $MainLayout/BattleArea/PlayerSection/HUD/PileCounters/DiscardPileLabel
@onready var _player_stats_box: VBoxContainer  = $MainLayout/BattleArea/PlayerSection/PlayerArea/PlayerStatsBox
@onready var _player_hp_label: Label           = $MainLayout/BattleArea/PlayerSection/PlayerArea/PlayerStatsBox/PlayerHPLabel
@onready var _player_health_bar: ProgressBar   = $MainLayout/BattleArea/PlayerSection/PlayerArea/PlayerStatsBox/PlayerHealthBar
@onready var _player_block_label: Label        = $MainLayout/BattleArea/PlayerSection/PlayerArea/PlayerStatsBox/PlayerBlockLabel
@onready var _player_visual_slot: Control      = $MainLayout/BattleArea/PlayerSection/PlayerArea/PlayerVisualSlot
@onready var _player_visual_placeholder: Label = $MainLayout/BattleArea/PlayerSection/PlayerArea/PlayerVisualSlot/PlayerVisualPlaceholder
@onready var _energy_label: Label              = $MainLayout/BattleArea/PlayerSection/HUD/EnergyLabel
@onready var _energy_pips_row: HBoxContainer   = $MainLayout/BattleArea/PlayerSection/PlayerArea/PlayerStatsBox/EnergyPips
@onready var _deck_viewer: DeckViewer          = $DeckViewer
@onready var _combat_result: CombatResult      = $CombatResult
@onready var _combat_reward: CombatReward      = $CombatReward
@onready var _toast: Toast                     = $Toast
@onready var _btn_draw_pile: Button            = $DrawPileButton
@onready var _btn_full_deck: Button            = $DeckButton
@onready var _btn_discard: Button              = $DiscardButton
@onready var _btn_exile: Button                = $ExileButton
@onready var _gold_label: Label                = $GoldLabel

# ── Runtime ────────────────────────────────────────────────────────────────────

var _combat_manager: CombatManager = null
var _deck: Deck = null
var _enemies: Array[Enemy] = []
var _pending_card: CardData = null
var _energy_pips: Array[Panel] = []
var _combat_over: bool = false
var _player_visual: CharacterVisual = null
var _gold_reward: int = 0

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	if player_data == null or enemy_data_list.is_empty():
		return
	_setup_combat()

# ── Setup ──────────────────────────────────────────────────────────────────────

func _setup_combat() -> void:
	_deck = Deck.new()
	if RunState.active_run != null:
		_deck.load_from_run(RunState.active_run)
	else:
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
	_combat_manager.exile_pile_changed.connect(_on_exile_pile_changed)
	_combat_manager.special_action_triggered.connect(_on_special_action_triggered)
	_combat_manager.enemy_died.connect(_on_enemy_died)
	_combat_manager.player_turn_began.connect(_on_player_turn_began)
	_combat_manager.enemy_turn_began.connect(_on_enemy_turn_began)
	_combat_manager.combat_ended.connect(_on_combat_ended)
	_combat_manager.player_attacked.connect(_on_player_attacked)
	_combat_manager.player_took_damage.connect(_on_player_took_damage)

	_setup_player_visual()

	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_btn_full_deck.pressed.connect(_on_btn_full_deck_pressed)
	_btn_draw_pile.pressed.connect(_on_btn_draw_pile_pressed)
	_btn_discard.pressed.connect(_on_btn_discard_pressed)
	_btn_exile.pressed.connect(_on_btn_exile_pressed)
	_hand_area.card_play_requested.connect(_on_card_play_requested)
	_hand_area.card_drag_play_requested.connect(_on_card_drag_play_requested)

	_player_health_bar.max_value = player_data.base_max_health + \
			player_data.constitution * CombatPlayer.HP_PER_CONSTITUTION

	# Move energy label from HUD into the player stats box
	_energy_label.reparent(_player_stats_box)
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	_btn_full_deck.text = "Deck  %d" % _deck.total_count()
	if RunState.active_run != null:
		_gold_label.text = "Gold: %d" % RunState.active_run.gold
	_combat_manager.start_combat()

# ── Player visual setup ────────────────────────────────────────────────────────

func _setup_player_visual() -> void:
	if player_data == null or player_data.visual_scene == null:
		return

	var viewport_container: SubViewportContainer = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player_visual_slot.add_child(viewport_container)

	var viewport: SubViewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport_container.add_child(viewport)

	_player_visual = player_data.visual_scene.instantiate() as CharacterVisual
	var scale_factor: float = minf(
		VISUAL_SLOT_SIZE.x / VISUAL_FRAME_SIZE.x,
		VISUAL_SLOT_SIZE.y / VISUAL_FRAME_SIZE.y
	)
	_player_visual.position = Vector2(VISUAL_SLOT_SIZE.x * 0.5, VISUAL_SLOT_SIZE.y * 0.5)
	_player_visual.scale = Vector2(scale_factor, scale_factor)
	viewport.add_child(_player_visual)

	_player_visual_placeholder.hide()

# ── Input ──────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _pending_card == null:
		return
	if _deck_viewer.visible:
		return
	var cancel: bool = (event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed) \
			or event.is_action_pressed("ui_cancel")
	if cancel:
		_cancel_targeting()
		get_viewport().set_input_as_handled()

# ── Card play / targeting ──────────────────────────────────────────────────────

func _on_card_play_requested(card_data: CardData) -> void:
	if not _combat_manager.can_play(card_data):
		_toast.show_message("Not enough energy")
		return
	if _needs_enemy_target(card_data):
		_pending_card = card_data
		_enter_targeting_mode()
	else:
		_combat_manager.play_card(card_data, null)

func _on_card_drag_play_requested(card_data: CardData, release_pos: Vector2) -> void:
	if not _combat_manager.can_play(card_data):
		_toast.show_message("Not enough energy")
		_hand_area.return_dragged_card(card_data)
		return
	if _needs_enemy_target(card_data):
		for enemy: Enemy in _enemies:
			if enemy.is_dead():
				continue
			if enemy.get_global_rect().has_point(release_pos):
				_combat_manager.play_card(card_data, enemy)
				return
		_hand_area.return_dragged_card(card_data)
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

# ── Targeting visuals ──────────────────────────────────────────────────────────

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

# ── End turn ───────────────────────────────────────────────────────────────────

func _on_end_turn_pressed() -> void:
	if _pending_card != null:
		_cancel_targeting()
	_combat_manager.end_player_turn()

# ── Deck viewer ────────────────────────────────────────────────────────────────

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

func _on_btn_exile_pressed() -> void:
	_deck_viewer.open("Exile", _deck.get_exile_pile())

# ── UI signal handlers ─────────────────────────────────────────────────────────

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
	_btn_draw_pile.text = "Draw  %d" % count

func _on_discard_pile_changed(count: int) -> void:
	_discard_pile_label.text = "Discard: %d" % count
	_btn_discard.text = "Discard  %d" % count

func _on_exile_pile_changed(count: int) -> void:
	_btn_exile.text = "Exile  %d" % count

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
	enemy.modulate.a = 1.0

func _on_player_turn_began(_energy: int, _max_energy: int) -> void:
	_end_turn_button.disabled = false

func _on_enemy_turn_began() -> void:
	_end_turn_button.disabled = true

func _on_player_attacked() -> void:
	if _player_visual != null:
		_player_visual.play_attack()

func _on_player_took_damage() -> void:
	if _player_visual != null:
		_player_visual.play_damaged()

func _on_combat_ended(victory: bool) -> void:
	_combat_over = true
	_end_turn_button.disabled = true
	_exit_targeting_mode()
	_hand_area.discard_all()
	if not victory and _player_visual != null:
		_player_visual.play_death()
	if victory:
		_gold_reward = _calculate_gold_reward()
	await get_tree().create_timer(0.5).timeout
	_combat_result.show_result(victory)
	_cleanup_enemies()
	_combat_result.continue_pressed.connect(func() -> void:
		if victory:
			_show_card_reward()
		else:
			combat_completed.emit(false),
		CONNECT_ONE_SHOT)

func _calculate_gold_reward() -> int:
	var total: int = 0
	for enemy: Enemy in _enemies:
		if enemy.data == null:
			continue
		var tier_range: Vector2i = GOLD_RANGE_BY_TIER.get(enemy.data.tier, Vector2i(5, 10))
		total += randi_range(tier_range.x, tier_range.y)
	return total

func _show_card_reward() -> void:
	var combat_type: CombatReward.CombatType
	match room_type:
		RoomData.RoomType.ELITE:
			combat_type = CombatReward.CombatType.ELITE
		RoomData.RoomType.BOSS:
			combat_type = CombatReward.CombatType.BOSS
		_:
			combat_type = CombatReward.CombatType.STANDARD
	_combat_reward.open(combat_type, _gold_reward)
	_combat_reward.reward_completed.connect(
			func() -> void: combat_completed.emit(true), CONNECT_ONE_SHOT)

func _cleanup_enemies() -> void:
	for enemy: Enemy in _enemies:
		enemy.queue_free()
	_enemies.clear()

# ── Energy pips ────────────────────────────────────────────────────────────────

func _ensure_energy_pips(max_energy: int) -> void:
	if not _energy_pips.is_empty():
		return
	for _i: int in max_energy:
		var pip: Panel = Panel.new()
		pip.custom_minimum_size = Vector2(16, 16)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.set_border_width_all(1)
		style.border_color = PIP_BORDER
		pip.add_theme_stylebox_override("panel", style)
		_energy_pips_row.add_child(pip)
		_energy_pips.append(pip)

func _refresh_energy_pips(current_energy: int) -> void:
	for i: int in _energy_pips.size():
		var style: StyleBoxFlat = _energy_pips[i].get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.bg_color = PIP_FILLED if i < current_energy else PIP_EMPTY
