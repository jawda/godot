class_name LevelUpScreen
extends Control

signal closed

const STAT_DATA: Array[Dictionary] = [
	{ "key": "strength",     "label": "Strength",     "color": Color(0.90, 0.35, 0.25, 1.0), "description": "+1 to attack damage per card" },
	{ "key": "dexterity",    "label": "Dexterity",    "color": Color(0.35, 0.82, 0.45, 1.0), "description": "+1 bonus block per block gain" },
	{ "key": "constitution", "label": "Constitution",  "color": Color(0.30, 0.70, 0.90, 1.0), "description": "+10 maximum HP" },
	{ "key": "intelligence", "label": "Intelligence",  "color": Color(0.60, 0.60, 0.95, 1.0), "description": "Unlocks future abilities" },
	{ "key": "faith",        "label": "Faith",         "color": Color(0.90, 0.78, 0.22, 1.0), "description": "+10% to all healing" },
]

# ── Node references ────────────────────────────────────────────────────────────

@onready var _subtitle: Label          = $Panel/Contents/Header/Info/Subtitle
@onready var _stat_list: VBoxContainer = $Panel/Contents/StatArea/StatList

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 10
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()

# ── Public API ─────────────────────────────────────────────────────────────────

func open() -> void:
	var run: RunSaveData = RunState.active_run
	if run == null or run.pending_stat_choices <= 0:
		closed.emit()
		return
	_rebuild_rows(run)
	show()

# ── Row builder ────────────────────────────────────────────────────────────────

func _rebuild_rows(run: RunSaveData) -> void:
	for child: Node in _stat_list.get_children():
		child.queue_free()
	var choices: int = run.pending_stat_choices
	_subtitle.text = "Choose a stat to improve" if choices <= 1 \
			else "Choose a stat to improve  (%d remaining)" % choices
	for stat: Dictionary in STAT_DATA:
		_stat_list.add_child(_build_stat_row(stat, run))

func _build_stat_row(stat: Dictionary, run: RunSaveData) -> Control:
	var stat_key: String   = stat["key"]
	var stat_color: Color  = stat["color"]
	var current_value: int = _current_stat_value(stat_key, run)

	var row: PanelContainer = PanelContainer.new()

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.11, 0.07, 0.18, 1.0)
	normal_style.set_border_width_all(1)
	normal_style.border_color = stat_color.darkened(0.4)
	normal_style.set_corner_radius_all(5)
	normal_style.content_margin_left   = 14.0
	normal_style.content_margin_right  = 14.0
	normal_style.content_margin_top    = 10.0
	normal_style.content_margin_bottom = 10.0

	var hover_style: StyleBoxFlat = StyleBoxFlat.new()
	hover_style.bg_color = stat_color.darkened(0.62)
	hover_style.set_border_width_all(2)
	hover_style.border_color = stat_color
	hover_style.set_corner_radius_all(5)
	hover_style.content_margin_left   = 14.0
	hover_style.content_margin_right  = 14.0
	hover_style.content_margin_top    = 10.0
	hover_style.content_margin_bottom = 10.0

	row.add_theme_stylebox_override("panel", normal_style)
	row.mouse_entered.connect(func() -> void:
		row.add_theme_stylebox_override("panel", hover_style))
	row.mouse_exited.connect(func() -> void:
		row.add_theme_stylebox_override("panel", normal_style))
	row.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton \
				and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT \
				and (event as InputEventMouseButton).pressed:
			_on_stat_chosen(stat_key))

	var content: HBoxContainer = HBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	row.add_child(content)

	var name_col: VBoxContainer = VBoxContainer.new()
	name_col.custom_minimum_size = Vector2(140, 0)
	name_col.add_theme_constant_override("separation", 2)
	content.add_child(name_col)

	var name_label: Label = Label.new()
	name_label.text = stat["label"]
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", stat_color)
	name_col.add_child(name_label)

	var desc_label: Label = Label.new()
	desc_label.text = stat["description"]
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.58, 0.52, 0.68, 1.0))
	name_col.add_child(desc_label)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var value_label: Label = Label.new()
	value_label.text = "%d  →  %d" % [current_value, current_value + 1]
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.96, 1.0))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(value_label)

	return row

# ── Stat helpers ───────────────────────────────────────────────────────────────

func _current_stat_value(stat_key: String, run: RunSaveData) -> int:
	var player_data: PlayerData = RunState.active_player
	var base_value: int = 0
	if player_data != null:
		match stat_key:
			"strength":     base_value = player_data.strength
			"dexterity":    base_value = player_data.dexterity
			"constitution": base_value = player_data.constitution
			"intelligence": base_value = player_data.intelligence
			"faith":        base_value = player_data.faith
	var bonus_value: int = 0
	match stat_key:
		"strength":     bonus_value = run.bonus_strength
		"dexterity":    bonus_value = run.bonus_dexterity
		"constitution": bonus_value = run.bonus_constitution
		"intelligence": bonus_value = run.bonus_intelligence
		"faith":        bonus_value = run.bonus_faith
	return base_value + bonus_value

func _on_stat_chosen(stat_key: String) -> void:
	var run: RunSaveData = RunState.active_run
	if run == null:
		return
	match stat_key:
		"strength":
			run.bonus_strength += 1
		"dexterity":
			run.bonus_dexterity += 1
		"constitution":
			run.bonus_constitution += 1
			run.current_max_health += CombatPlayer.HP_PER_CONSTITUTION
			run.current_health     += CombatPlayer.HP_PER_CONSTITUTION
		"intelligence":
			run.bonus_intelligence += 1
		"faith":
			run.bonus_faith += 1
	run.pending_stat_choices -= 1
	SaveManager.save()
	if run.pending_stat_choices <= 0:
		hide()
		closed.emit()
	else:
		_rebuild_rows(run)
