class_name CardPicker
extends Control

## Full-screen overlay that lets the player click one card from a provided list.
## Emits card_chosen(card) when a row is selected, then closes automatically.
## The static chrome (backdrop, panel, header, scroll container) lives in card_picker.tscn.
## The card rows are built dynamically by open() and cleared on each call.

signal card_chosen(card: CardData)

# ── Constants ──────────────────────────────────────────────────────────────────

const RARITY_COLORS: Array[Color] = [
	Color(0.52, 0.52, 0.52, 1.0),   # COMMON
	Color(0.38, 0.65, 0.38, 1.0),   # UNCOMMON
	Color(0.32, 0.52, 0.82, 1.0),   # RARE
	Color(0.62, 0.32, 0.82, 1.0),   # MYTHIC
	Color(0.78, 0.65, 0.12, 1.0),   # SPECIAL
]
const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Mythic", "Special"]

const CARD_W: float      = 160.0
const CARD_H: float      = 240.0
const PANEL_W: float     = 540.0
const CARD_SCENE: PackedScene = preload("res://cards/card.tscn")

# ── Node references ─────────────────────────────────────────────────────────────

@onready var _title_label: Label       = $Panel/Contents/Header/HeaderRow/Title
@onready var _close_button: Button     = $Panel/Contents/Header/HeaderRow/Close
@onready var _card_list: VBoxContainer = $Panel/Contents/Scroll/CardPadding/CardList

# ── Preview ─────────────────────────────────────────────────────────────────────

var _card_preview: Card = null

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_close_button.pressed.connect(close)
	_card_preview = CARD_SCENE.instantiate() as Card
	_card_preview.pivot_offset = Vector2.ZERO
	_card_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_preview.z_index = 2
	_card_preview.hide()
	add_child(_card_preview)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

# ── Public API ─────────────────────────────────────────────────────────────────

func open(title: String, cards: Array[CardData]) -> void:
	_title_label.text = title
	for child: Node in _card_list.get_children():
		child.queue_free()
	for card: CardData in cards:
		_card_list.add_child(_build_card_row(card))
	_reposition_preview()
	show()

func close() -> void:
	hide()
	_hide_preview()

# ── Row builder ────────────────────────────────────────────────────────────────

func _build_card_row(card: CardData) -> Control:
	var rarity_index: int = card.effective_rarity as int
	var rarity_color: Color = RARITY_COLORS[rarity_index]

	var row: PanelContainer = PanelContainer.new()

	var row_normal_style: StyleBoxFlat = StyleBoxFlat.new()
	row_normal_style.bg_color = Color(0.11, 0.07, 0.18, 1.0)
	row_normal_style.set_border_width_all(1)
	row_normal_style.border_color = Color(0.28, 0.16, 0.42, 1.0)
	row_normal_style.set_corner_radius_all(4)
	row_normal_style.content_margin_left   = 10.0
	row_normal_style.content_margin_right  = 14.0
	row_normal_style.content_margin_top    = 6.0
	row_normal_style.content_margin_bottom = 6.0

	var row_hover_style: StyleBoxFlat = StyleBoxFlat.new()
	row_hover_style.bg_color = Color(0.24, 0.14, 0.38, 1.0)
	row_hover_style.set_border_width_all(2)
	row_hover_style.border_color = rarity_color
	row_hover_style.set_corner_radius_all(4)
	row_hover_style.content_margin_left   = 10.0
	row_hover_style.content_margin_right  = 14.0
	row_hover_style.content_margin_top    = 6.0
	row_hover_style.content_margin_bottom = 6.0

	row.add_theme_stylebox_override("panel", row_normal_style)

	row.mouse_entered.connect(func() -> void:
		row.add_theme_stylebox_override("panel", row_hover_style)
		_show_preview(card))
	row.mouse_exited.connect(func() -> void:
		row.add_theme_stylebox_override("panel", row_normal_style)
		_hide_preview())
	row.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton \
				and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT \
				and (event as InputEventMouseButton).pressed:
			close()
			card_chosen.emit(card))

	var row_content: HBoxContainer = HBoxContainer.new()
	row_content.add_theme_constant_override("separation", 12)
	row.add_child(row_content)

	# Cost badge
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

	# Name + type column
	var name_column: VBoxContainer = VBoxContainer.new()
	name_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_column.add_theme_constant_override("separation", 1)
	row_content.add_child(name_column)

	var name_label: Label = Label.new()
	name_label.text = card.card_name + (" +" if card.upgraded else "")
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.85, 1.0, 1.0))
	name_column.add_child(name_label)

	var type_label: Label = Label.new()
	type_label.text = "— %s" % card.get_type_label()
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.add_theme_color_override("font_color", Color(0.55, 0.48, 0.68, 1.0))
	name_column.add_child(type_label)

	# Rarity label
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
