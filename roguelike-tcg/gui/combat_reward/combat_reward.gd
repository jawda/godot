class_name CombatReward
extends Control

## Full-screen overlay shown after a victory. Rolls 3 card rewards using a
## weighted rarity system (STS-style) and lets the player pick one or skip.
## Emits reward_completed when the overlay is dismissed (pick or skip).

signal reward_completed

enum CombatType { STANDARD, ELITE, BOSS }

# ── Constants ──────────────────────────────────────────────────────────────────

const RARITY_COLORS: Array[Color] = [
	Color(0.52, 0.52, 0.52, 1.0),   # COMMON
	Color(0.38, 0.65, 0.38, 1.0),   # UNCOMMON
	Color(0.32, 0.52, 0.82, 1.0),   # RARE
	Color(0.62, 0.32, 0.82, 1.0),   # MYTHIC
	Color(0.78, 0.65, 0.12, 1.0),   # SPECIAL
]
const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Mythic", "Special"]

const CARD_W: float = 160.0
const CARD_H: float = 240.0
const PANEL_W: float = 540.0
const REWARD_COUNT: int = 3
const CARDS_DATA_PATH: String = "res://cards/data"

# Regular combat: base rare chance starts very low (-2%), offset needed to see rares.
const BASE_RARE_STANDARD: float = -2.0
# Elite combat: meaningful base rare chance out of the gate.
const BASE_RARE_ELITE: float = 5.0
const RARITY_OFFSET_RESET: float = -5.0

const CARD_SCENE: PackedScene = preload("res://cards/card.tscn")

# ── Node references ────────────────────────────────────────────────────────────

@onready var _title_label: Label           = $Panel/Contents/Header/Title
@onready var _card_list: VBoxContainer     = $Panel/Contents/Scroll/CardPadding/CardList
@onready var _skip_button: Button          = $Panel/Contents/Footer/Skip

# ── Preview ────────────────────────────────────────────────────────────────────

var _card_preview: Card = null

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 10
	hide()
	_skip_button.pressed.connect(_on_skip_pressed)
	_card_preview = CARD_SCENE.instantiate() as Card
	_card_preview.pivot_offset = Vector2.ZERO
	_card_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_preview.z_index = 2
	_card_preview.hide()
	add_child(_card_preview)

# ── Public API ─────────────────────────────────────────────────────────────────

func open(combat_type: CombatType) -> void:
	var run: RunSaveData = RunState.active_run
	if run == null:
		reward_completed.emit()
		return

	var player_class_string: String = ""
	if RunState.active_player != null:
		player_class_string = RunState.active_player.character_class

	var pool: Array[CardData] = _load_card_pool(player_class_string)
	var offered: Array[CardData] = _roll_rewards(combat_type, run, pool)
	_apply_offset_update(offered, run)

	for child: Node in _card_list.get_children():
		child.queue_free()

	if offered.is_empty():
		reward_completed.emit()
		return

	for card: CardData in offered:
		_card_list.add_child(_build_card_row(card))

	_reposition_preview()
	show()

# ── Rarity rolling ─────────────────────────────────────────────────────────────

func _roll_rewards(combat_type: CombatType, run: RunSaveData, pool: Array[CardData]) -> Array[CardData]:
	var offered: Array[CardData] = []
	for _i: int in REWARD_COUNT:
		var rarity: CardData.Rarity = _roll_rarity(combat_type, run.rarity_offset)
		var candidates: Array[CardData] = _cards_of_rarity(pool, rarity, offered)
		if candidates.is_empty():
			rarity = _fallback_rarity(rarity, pool, offered)
			candidates = _cards_of_rarity(pool, rarity, offered)
		if candidates.is_empty():
			continue
		offered.append(candidates[randi() % candidates.size()])
	return offered

func _roll_rarity(combat_type: CombatType, offset: float) -> CardData.Rarity:
	if combat_type == CombatType.BOSS:
		return CardData.Rarity.RARE

	var base_rare: float = BASE_RARE_STANDARD if combat_type == CombatType.STANDARD else BASE_RARE_ELITE
	var effective_rare: float = maxf(0.0, base_rare + offset)
	var roll: float = randf() * 100.0

	if roll < effective_rare:
		return CardData.Rarity.RARE

	# Remaining probability split 60% Common / 40% Uncommon.
	var remaining: float = 100.0 - effective_rare
	if roll < effective_rare + remaining * 0.6:
		return CardData.Rarity.COMMON
	return CardData.Rarity.UNCOMMON

func _fallback_rarity(desired: CardData.Rarity, pool: Array[CardData], exclude: Array[CardData]) -> CardData.Rarity:
	var target: int = (desired as int) - 1
	while target >= 0:
		var rarity: CardData.Rarity = target as CardData.Rarity
		if not _cards_of_rarity(pool, rarity, exclude).is_empty():
			return rarity
		target -= 1
	return desired

func _cards_of_rarity(pool: Array[CardData], rarity: CardData.Rarity, exclude: Array[CardData]) -> Array[CardData]:
	var result: Array[CardData] = []
	for card: CardData in pool:
		if card.base_rarity == rarity and not exclude.has(card):
			result.append(card)
	return result

func _apply_offset_update(offered: Array[CardData], run: RunSaveData) -> void:
	var commons_rolled: int = 0
	var rare_rolled: bool = false
	for card: CardData in offered:
		if card.base_rarity == CardData.Rarity.COMMON:
			commons_rolled += 1
		if card.base_rarity == CardData.Rarity.RARE:
			rare_rolled = true
	run.rarity_offset += float(commons_rolled)
	if rare_rolled:
		run.rarity_offset = RARITY_OFFSET_RESET
	SaveManager.save()

# ── Card pool ──────────────────────────────────────────────────────────────────

func _load_card_pool(player_class_string: String) -> Array[CardData]:
	var result: Array[CardData] = []
	_scan_directory(CARDS_DATA_PATH, player_class_string, result)
	return result

func _scan_directory(dir_path: String, player_class_string: String, result: Array[CardData]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			_scan_directory(dir_path + "/" + entry, player_class_string, result)
		elif entry.ends_with(".tres"):
			var resource: Resource = load(dir_path + "/" + entry)
			if resource is CardData:
				var card: CardData = resource as CardData
				if card.in_reward_pool and not card.is_token and _is_class_match(card, player_class_string):
					result.append(card)
		entry = dir.get_next()
	dir.list_dir_end()

func _is_class_match(card: CardData, player_class_string: String) -> bool:
	if card.card_class == CardData.CardClass.NEUTRAL:
		return true
	match card.card_class:
		CardData.CardClass.CLERIC:
			return player_class_string == "cleric"
	return false

# ── Card selection ─────────────────────────────────────────────────────────────

func _on_skip_pressed() -> void:
	_hide_preview()
	hide()
	reward_completed.emit()

func _on_card_chosen(card: CardData) -> void:
	var run: RunSaveData = RunState.active_run
	if run != null:
		run.deck_card_paths.append(card.resource_path)
		run.deck_card_upgrades.append(false)
		SaveManager.save()
	_hide_preview()
	hide()
	reward_completed.emit()

# ── Row builder ────────────────────────────────────────────────────────────────

func _build_card_row(card: CardData) -> Control:
	var rarity_index: int = card.base_rarity as int
	var rarity_color: Color = RARITY_COLORS[rarity_index]

	var row: PanelContainer = PanelContainer.new()

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.11, 0.07, 0.18, 1.0)
	normal_style.set_border_width_all(1)
	normal_style.border_color = Color(0.28, 0.16, 0.42, 1.0)
	normal_style.set_corner_radius_all(4)
	normal_style.content_margin_left   = 10.0
	normal_style.content_margin_right  = 14.0
	normal_style.content_margin_top    = 6.0
	normal_style.content_margin_bottom = 6.0

	var hover_style: StyleBoxFlat = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.24, 0.14, 0.38, 1.0)
	hover_style.set_border_width_all(2)
	hover_style.border_color = rarity_color
	hover_style.set_corner_radius_all(4)
	hover_style.content_margin_left   = 10.0
	hover_style.content_margin_right  = 14.0
	hover_style.content_margin_top    = 6.0
	hover_style.content_margin_bottom = 6.0

	row.add_theme_stylebox_override("panel", normal_style)

	row.mouse_entered.connect(func() -> void:
		row.add_theme_stylebox_override("panel", hover_style)
		_show_preview(card))
	row.mouse_exited.connect(func() -> void:
		row.add_theme_stylebox_override("panel", normal_style)
		_hide_preview())
	row.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton \
				and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT \
				and (event as InputEventMouseButton).pressed:
			_on_card_chosen(card))

	var row_content: HBoxContainer = HBoxContainer.new()
	row_content.add_theme_constant_override("separation", 12)
	row.add_child(row_content)

	var cost_wrap: PanelContainer = PanelContainer.new()
	cost_wrap.custom_minimum_size = Vector2(28, 28)
	cost_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cost_style: StyleBoxFlat = StyleBoxFlat.new()
	cost_style.bg_color     = rarity_color.darkened(0.45)
	cost_style.set_border_width_all(1)
	cost_style.border_color = rarity_color
	cost_style.set_corner_radius_all(4)
	cost_style.content_margin_left   = 0.0
	cost_style.content_margin_right  = 0.0
	cost_style.content_margin_top    = 0.0
	cost_style.content_margin_bottom = 0.0
	cost_wrap.add_theme_stylebox_override("panel", cost_style)

	var cost_label: Label = Label.new()
	cost_label.text = str(card.card_cost)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 14)
	cost_label.add_theme_color_override("font_color", Color.WHITE)
	cost_wrap.add_child(cost_label)
	row_content.add_child(cost_wrap)

	var name_column: VBoxContainer = VBoxContainer.new()
	name_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_column.add_theme_constant_override("separation", 1)
	row_content.add_child(name_column)

	var name_label: Label = Label.new()
	name_label.text = card.card_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.85, 1.0, 1.0))
	name_column.add_child(name_label)

	var type_label: Label = Label.new()
	type_label.text = "— %s" % card.get_type_label()
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.add_theme_color_override("font_color", Color(0.55, 0.48, 0.68, 1.0))
	name_column.add_child(type_label)

	var rarity_label: Label = Label.new()
	rarity_label.text = RARITY_NAMES[rarity_index]
	rarity_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rarity_label.add_theme_font_size_override("font_size", 11)
	rarity_label.add_theme_color_override("font_color", rarity_color)
	row_content.add_child(rarity_label)

	return row

# ── Preview ────────────────────────────────────────────────────────────────────

func _show_preview(card: CardData) -> void:
	if _card_preview == null:
		return
	_card_preview.data = card
	_card_preview.show()

func _hide_preview() -> void:
	if _card_preview != null:
		_card_preview.hide()

func _reposition_preview() -> void:
	if _card_preview == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var panel_right: float = (viewport_size.x + PANEL_W) * 0.5
	var right_gap: float   = viewport_size.x - panel_right
	var panel_left: float  = (viewport_size.x - PANEL_W) * 0.5

	var preview_x: float
	if right_gap >= CARD_W + 8.0:
		preview_x = panel_right + (right_gap - CARD_W) * 0.5
	else:
		preview_x = panel_left - CARD_W - (panel_left - CARD_W) * 0.5
	preview_x = clampf(preview_x, 4.0, viewport_size.x - CARD_W - 4.0)

	var preview_y: float = clampf(
			(viewport_size.y - CARD_H) * 0.5, 4.0, viewport_size.y - CARD_H - 4.0)
	_card_preview.position = Vector2(preview_x, preview_y)
