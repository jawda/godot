@tool
class_name Card
extends Control

const RARITY_LABELS: Array[String] = ["Common", "Uncommon", "Rare", "✦ Mythic ✦", "✦ Special ✦"]
const SIZE := Vector2(160, 240)

# ── Card data ──────────────────────────────────────────────────────────────────

@export var data: CardData:
	set(new_data):
		if data and data.changed.is_connected(_on_data_changed):
			data.changed.disconnect(_on_data_changed)
		data = new_data
		if data:
			data.changed.connect(_on_data_changed)
		if is_node_ready():
			_apply_palette()
			_update_labels()

func _on_data_changed() -> void:
	_apply_palette()
	_update_labels()

# ── Palettes ───────────────────────────────────────────────────────────────────
# Loaded from res://cards/palettes/*.tres — edit those files to change colors.
# Order must match CardData.Rarity enum (COMMON=0 … SPECIAL=4).

const PALETTES: Array[CardPalette] = [
	preload("res://cards/palettes/common.tres"),
	preload("res://cards/palettes/uncommon.tres"),
	preload("res://cards/palettes/rare.tres"),
	preload("res://cards/palettes/mythic.tres"),
	preload("res://cards/palettes/special.tres"),
]

# ── Node references ────────────────────────────────────────────────────────────

@onready var _card_body: Panel          = $CardBody
@onready var _cost_badge: Panel         = $CardBody/CostBadge
@onready var _cost_label: Label         = $CardBody/CostBadge/CostLabel
@onready var _art_frame: Panel          = $CardBody/ArtFrame
@onready var _art_label: Label          = $CardBody/ArtFrame/ArtLabel
@onready var _name_banner: Panel        = $CardBody/NameBanner
@onready var _card_name_label: Label    = $CardBody/NameBanner/CardName
@onready var _type_label: Label         = $CardBody/TypeLabel
@onready var _description_box: Panel    = $CardBody/DescriptionBox
@onready var _description_text: RichTextLabel = $CardBody/DescriptionBox/DescriptionText
@onready var _rarity_strip: Panel       = $CardBody/DescriptionBox/RarityStrip
@onready var _rarity_label: Label       = $CardBody/DescriptionBox/RarityStrip/RarityLabel

# ── Internal state ─────────────────────────────────────────────────────────────

var _base_scale: Vector2 = Vector2.ONE
var _resting_y: float = 0.0
var _pulse_tween: Tween
var _hover_tween: Tween
var _body_style: StyleBoxFlat

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_base_scale = scale
	if data == null:
		data = CardData.new()
	_apply_palette()
	_update_labels()

# ── Palette application ────────────────────────────────────────────────────────

func _apply_palette() -> void:
	if data == null:
		return
	var palette: CardPalette = PALETTES[data.effective_rarity]

	# Kill any existing pulse so switching rarities is clean
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null

	# Card body — store reference for pulse animation
	_body_style = _make_style(palette.body_bg, palette.border,
			8, palette.border_width, palette.shadow, palette.shadow_base)
	_card_body.add_theme_stylebox_override("panel", _body_style)

	# Cost badge
	var cost_shadow: Color = Color(palette.shadow.r, palette.shadow.g, palette.shadow.b, 0.6)
	var cost_style: StyleBoxFlat = _make_style(palette.cost_bg, palette.cost_border, 13, palette.border_width, cost_shadow, 4)
	_cost_badge.add_theme_stylebox_override("panel", cost_style)
	_cost_label.add_theme_color_override("font_color", palette.cost_text)

	# Art frame
	var art_style: StyleBoxFlat = _make_style(palette.body_bg.lightened(0.04), palette.art_border, 4, 1)
	_art_frame.add_theme_stylebox_override("panel", art_style)
	_art_label.add_theme_color_override("font_color", palette.art_border * Color(1, 1, 1, 0.9))

	# Name banner
	var name_style: StyleBoxFlat = StyleBoxFlat.new()
	name_style.bg_color = palette.name_bg
	name_style.set_border_width_all(1)
	name_style.border_color = palette.name_border
	name_style.set_corner_radius_all(8)
	_name_banner.add_theme_stylebox_override("panel", name_style)

	_card_name_label.add_theme_color_override("font_color", palette.name_text)
	_card_name_label.add_theme_constant_override("outline_size", palette.name_outline_size)
	_card_name_label.add_theme_color_override("font_outline_color", palette.name_outline)

	# Type label
	_type_label.add_theme_color_override("font_color", palette.type_text)

	# Description box
	var desc_style: StyleBoxFlat = _make_style(palette.body_bg.darkened(0.15), palette.desc_border, 4, 1)
	desc_style.content_margin_left   = 6.0
	desc_style.content_margin_top    = 5.0
	desc_style.content_margin_right  = 6.0
	desc_style.content_margin_bottom = 5.0
	_description_box.add_theme_stylebox_override("panel", desc_style)
	_description_text.add_theme_color_override("default_color", palette.desc_text)

	# Rarity strip — width varies by tier
	_rarity_strip.offset_left  = float(palette.rarity_strip_x0)
	_rarity_strip.offset_right = float(palette.rarity_strip_x1)
	var rarity_style: StyleBoxFlat = _make_style(palette.rarity_bg, palette.rarity_border, 6, 1)
	_rarity_strip.add_theme_stylebox_override("panel", rarity_style)
	_rarity_label.add_theme_color_override("font_color", palette.rarity_text)
	# Expand label to fill new strip width
	_rarity_label.offset_right = float(palette.rarity_strip_x1 - palette.rarity_strip_x0)

	# Pulsing glow for Mythic and Special
	if data.effective_rarity >= CardData.Rarity.MYTHIC:
		_start_pulse(palette.shadow_base, palette.shadow_peak)

func _start_pulse(base_size: int, peak_size: int) -> void:
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_method(_set_body_shadow, float(base_size), float(peak_size), 1.2) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_method(_set_body_shadow, float(peak_size), float(base_size), 1.2) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _set_body_shadow(shadow_size: float) -> void:
	if _body_style:
		_body_style.shadow_size = int(shadow_size)

func _make_style(background: Color, border: Color, radius: int = 6, border_width: int = 2,
		shadow: Color = Color.TRANSPARENT, shadow_size: int = 0) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.set_border_width_all(border_width)
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style

# ── Label updates ──────────────────────────────────────────────────────────────

func _update_labels() -> void:
	if data == null:
		return
	_cost_label.text = str(data.card_cost)
	_card_name_label.text = data.card_name
	_type_label.text = "— " + data.get_type_label() + " —"
	_description_text.text = data.get_description(data.upgraded)
	var rarity_text: String = RARITY_LABELS[data.effective_rarity]
	if data.upgraded:
		rarity_text += " +"
	_rarity_label.text = rarity_text

# ── Hover (mouse and controller focus) ────────────────────────────────────────

## Kills in-flight hover animation and resets scale. Called before drag takes over positioning.
func cancel_animations() -> void:
	if _hover_tween:
		_hover_tween.kill()
		_hover_tween = null
	scale = _base_scale

func set_hovered(is_hovered: bool) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel(true) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if is_hovered:
		z_index = 10
		_resting_y = position.y
		_hover_tween.tween_property(self, "scale", _base_scale * 1.08, 0.18)
		_hover_tween.tween_property(self, "position:y", position.y - 22.0, 0.18)
	else:
		z_index = 0
		_hover_tween.tween_property(self, "scale", _base_scale, 0.15)
		_hover_tween.tween_property(self, "position:y", _resting_y, 0.15)
