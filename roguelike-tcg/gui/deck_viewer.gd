class_name DeckViewer
extends Control

## Overlay panel for viewing a pile of cards during combat.
## Starts empty. open() builds and shows the UI. close() hides and destroys it.
## Hovering (or focusing with a controller) a row shows the full card preview.

# ── Rarity styling ────────────────────────────────────────────────────────────

const RARITY_COLORS: Array[Color] = [
	Color(0.52, 0.52, 0.52),   # COMMON
	Color(0.38, 0.65, 0.38),   # UNCOMMON
	Color(0.32, 0.52, 0.82),   # RARE
	Color(0.62, 0.32, 0.82),   # MYTHIC
	Color(0.78, 0.65, 0.12),   # SPECIAL
]
const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Mythic", "Special"]

const PANEL_W:   float = 660.0
const PANEL_H:   float = 580.0
const CARD_W:    float = 160.0
const CARD_H:    float = 240.0
const CARD_SCENE: PackedScene = preload("res://cards/card.tscn")

# ── Runtime ───────────────────────────────────────────────────────────────────

var _card_preview: Card      = null
var _preview_position: Vector2 = Vector2.ZERO

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 10
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

# ── Public API ────────────────────────────────────────────────────────────────

func open(title: String, cards: Array[CardData]) -> void:
	for child: Node in get_children():
		child.queue_free()
	_card_preview = null

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	position = Vector2.ZERO
	size     = viewport_size

	_build_backdrop(viewport_size)
	_build_panel(title, cards, viewport_size)
	_build_preview(viewport_size)
	show()

func close() -> void:
	hide()
	_card_preview = null
	for child: Node in get_children():
		child.queue_free()

# ── UI construction ───────────────────────────────────────────────────────────

func _build_backdrop(viewport_size: Vector2) -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size     = viewport_size
	backdrop.color    = Color(0.0, 0.0, 0.0, 0.72)
	backdrop.gui_input.connect(_on_backdrop_input)
	add_child(backdrop)

func _build_panel(title: String, cards: Array[CardData], viewport_size: Vector2) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2((viewport_size.x - PANEL_W) * 0.5, (viewport_size.y - PANEL_H) * 0.5)
	panel.size     = Vector2(PANEL_W, PANEL_H)

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color           = Color(0.07, 0.04, 0.12, 0.97)
	panel_style.set_border_width_all(1)
	panel_style.border_color       = Color(0.44, 0.22, 0.66)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left   = 0.0
	panel_style.content_margin_right  = 0.0
	panel_style.content_margin_top    = 0.0
	panel_style.content_margin_bottom = 0.0
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var panel_content: VBoxContainer = VBoxContainer.new()
	panel_content.add_theme_constant_override("separation", 0)
	panel.add_child(panel_content)

	panel_content.add_child(_build_header(title, cards.size()))

	var separator: HSeparator = HSeparator.new()
	separator.add_theme_color_override("color", Color(0.44, 0.22, 0.66, 0.5))
	panel_content.add_child(separator)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel_content.add_child(scroll)

	var card_list: VBoxContainer = VBoxContainer.new()
	card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_list.add_theme_constant_override("separation", 4)
	scroll.add_child(card_list)

	var padding: MarginContainer = MarginContainer.new()
	padding.add_theme_constant_override("margin_left",   12)
	padding.add_theme_constant_override("margin_right",  12)
	padding.add_theme_constant_override("margin_top",    8)
	padding.add_theme_constant_override("margin_bottom", 8)
	card_list.add_child(padding)

	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	padding.add_child(inner)

	for card: CardData in cards:
		inner.add_child(_build_card_row(card))

func _build_preview(viewport_size: Vector2) -> void:
	# Position the preview to the right of the panel, clamped to viewport.
	# Falls back to left side if there is not enough space on the right.
	var panel_right: float = (viewport_size.x + PANEL_W) * 0.5
	var right_gap:   float = viewport_size.x - panel_right
	var panel_left:  float = (viewport_size.x - PANEL_W) * 0.5

	var preview_x: float
	if right_gap >= CARD_W + 8.0:
		preview_x = panel_right + (right_gap - CARD_W) * 0.5
	else:
		preview_x = panel_left - CARD_W - (panel_left - CARD_W) * 0.5
	preview_x = clampf(preview_x, 4.0, viewport_size.x - CARD_W - 4.0)
	var preview_y: float = clampf((viewport_size.y - CARD_H) * 0.5, 4.0, viewport_size.y - CARD_H - 4.0)
	_preview_position = Vector2(preview_x, preview_y)

	_card_preview = CARD_SCENE.instantiate() as Card
	_card_preview.pivot_offset  = Vector2.ZERO   # predictable top-left origin
	_card_preview.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_card_preview.position      = _preview_position
	_card_preview.z_index       = 2
	_card_preview.hide()
	add_child(_card_preview)

func _build_header(title: String, count: int) -> Control:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   20)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    14)
	margin.add_theme_constant_override("margin_bottom", 14)

	var header_row: HBoxContainer = HBoxContainer.new()
	margin.add_child(header_row)

	var title_lbl: Label = Label.new()
	title_lbl.text = title
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.90, 0.80, 1.00))
	header_row.add_child(title_lbl)

	var count_lbl: Label = Label.new()
	count_lbl.text = "  (%d)" % count
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", Color(0.55, 0.45, 0.70))
	header_row.add_child(count_lbl)

	var close_btn: Button = Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.custom_minimum_size = Vector2(44, 0)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(0.80, 0.40, 0.40))
	close_btn.pressed.connect(close)
	header_row.add_child(close_btn)

	return margin

# ── Card row ──────────────────────────────────────────────────────────────────

func _build_card_row(card: CardData) -> Control:
	var rarity_idx: int = card.effective_rarity as int
	var rarity_color: Color = RARITY_COLORS[rarity_idx]

	var row: PanelContainer = PanelContainer.new()

	var row_style: StyleBoxFlat = StyleBoxFlat.new()
	row_style.bg_color = Color(0.11, 0.07, 0.18)
	row_style.set_border_width_all(1)
	row_style.border_color = Color(0.28, 0.16, 0.42)
	row_style.set_corner_radius_all(4)
	row_style.content_margin_left   = 10.0
	row_style.content_margin_right  = 14.0
	row_style.content_margin_top    = 6.0
	row_style.content_margin_bottom = 6.0

	var row_hover_style: StyleBoxFlat = StyleBoxFlat.new()
	row_hover_style.bg_color = Color(0.20, 0.12, 0.32)
	row_hover_style.set_border_width_all(1)
	row_hover_style.border_color = rarity_color
	row_hover_style.set_corner_radius_all(4)
	row_hover_style.content_margin_left   = 10.0
	row_hover_style.content_margin_right  = 14.0
	row_hover_style.content_margin_top    = 6.0
	row_hover_style.content_margin_bottom = 6.0

	row.add_theme_stylebox_override("panel", row_style)

	# Hover / controller-focus wiring for the card preview and row highlight
	row.mouse_entered.connect(func() -> void:
		row.add_theme_stylebox_override("panel", row_hover_style)
		_show_preview(card))
	row.mouse_exited.connect(func() -> void:
		row.add_theme_stylebox_override("panel", row_style)
		_hide_preview())
	row.focus_mode = Control.FOCUS_ALL
	row.focus_entered.connect(func() -> void:
		row.add_theme_stylebox_override("panel", row_hover_style)
		_show_preview(card))
	row.focus_exited.connect(func() -> void:
		row.add_theme_stylebox_override("panel", row_style)
		_hide_preview())

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

	var cost_lbl: Label = Label.new()
	cost_lbl.text = str(card.card_cost)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 14)
	cost_lbl.add_theme_color_override("font_color", Color.WHITE)
	cost_wrap.add_child(cost_lbl)
	row_content.add_child(cost_wrap)

	# Name + type column
	var name_col: VBoxContainer = VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.add_theme_constant_override("separation", 1)
	row_content.add_child(name_col)

	var name_lbl: Label = Label.new()
	name_lbl.text = card.card_name + (" +" if card.upgraded else "")
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.85, 1.0))
	name_col.add_child(name_lbl)

	var type_lbl: Label = Label.new()
	type_lbl.text = "— %s" % card.get_type_label()
	type_lbl.add_theme_font_size_override("font_size", 11)
	type_lbl.add_theme_color_override("font_color", Color(0.55, 0.48, 0.68))
	name_col.add_child(type_lbl)

	# Rarity label
	var rarity_lbl: Label = Label.new()
	rarity_lbl.text = RARITY_NAMES[rarity_idx]
	rarity_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rarity_lbl.add_theme_font_size_override("font_size", 11)
	rarity_lbl.add_theme_color_override("font_color", rarity_color)
	row_content.add_child(rarity_lbl)

	return row

# ── Card preview ──────────────────────────────────────────────────────────────

func _show_preview(card_data: CardData) -> void:
	if _card_preview == null:
		return
	_card_preview.data     = card_data
	_card_preview.position = _preview_position
	_card_preview.show()

func _hide_preview() -> void:
	if _card_preview != null:
		_card_preview.hide()

# ── Backdrop click ────────────────────────────────────────────────────────────

func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		close()
