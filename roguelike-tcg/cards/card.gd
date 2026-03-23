@tool
extends Control

enum Rarity { COMMON, UNCOMMON, RARE, MYTHIC, SPECIAL }
enum CardType { ATTACK, SKILL, POWER, CURSE, STATUS }

const CARD_TYPE_LABELS: Array[String] = ["Attack", "Skill", "Power", "Curse", "Status"]

# ── Exported properties with live-update setters ──────────────────────────────

@export_group("Card Data")
@export var card_name: String = "Void Strike":
	set(v):
		card_name = v
		if is_node_ready(): _update_labels()

@export var card_cost: int = 1:
	set(v):
		card_cost = v
		if is_node_ready(): _update_labels()

@export var card_type: CardType = CardType.ATTACK:
	set(v):
		card_type = v
		if is_node_ready(): _update_labels()

@export_multiline var card_description: String = "Deal [b]8[/b] damage.\nApply [color=#00e5c8]1 Void[/color].":
	set(v):
		card_description = v
		if is_node_ready(): _update_labels()

@export_group("Rarity")
@export var base_rarity: Rarity = Rarity.COMMON:
	set(v):
		base_rarity = v
		if is_node_ready():
			_apply_palette()
			_update_labels()

@export var upgraded: bool = false:
	set(v):
		upgraded = v
		if is_node_ready():
			_apply_palette()
			_update_labels()

# Effective rarity is what drives all visuals.
# Upgrading shifts the card up one tier, capped at SPECIAL.
var effective_rarity: Rarity:
	get: return mini(base_rarity + 1, Rarity.SPECIAL) as Rarity if upgraded else base_rarity

# ── Palettes ───────────────────────────────────────────────────────────────────
# Loaded from res://cards/palettes/*.tres — edit those files to change colors.
# Order must match the Rarity enum (COMMON=0 … SPECIAL=4).

const PALETTES: Array[CardPalette] = [
	preload("res://cards/palettes/common.tres"),
	preload("res://cards/palettes/uncommon.tres"),
	preload("res://cards/palettes/rare.tres"),
	preload("res://cards/palettes/mythic.tres"),
	preload("res://cards/palettes/special.tres"),
]

const RARITY_LABELS := ["Common", "Uncommon", "Rare", "✦ Mythic ✦", "✦ Special ✦"]

# ── Internal state ─────────────────────────────────────────────────────────────

var _base_scale    := Vector2.ONE
var _pulse_tween   : Tween
var _body_style    : StyleBoxFlat

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_base_scale = scale
	_apply_palette()
	_update_labels()
	if not Engine.is_editor_hint():
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)

# ── Palette application ────────────────────────────────────────────────────────

func _apply_palette() -> void:
	var p: CardPalette = PALETTES[effective_rarity]

	# Kill any existing pulse so switching rarities is clean
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null

	# Card body — store reference for pulse animation
	_body_style = _make_style(p.body_bg, p.border,
			8, p.border_width, p.shadow, p.shadow_base)
	$CardBody.add_theme_stylebox_override("panel", _body_style)

	# Cost badge
	var cost_shadow := Color(p.shadow.r, p.shadow.g, p.shadow.b, 0.6)
	var cost := _make_style(p.cost_bg, p.cost_border, 18, p.border_width, cost_shadow, 4)
	$CardBody/CostBadge.add_theme_stylebox_override("panel", cost)
	$CardBody/CostBadge/CostLabel.add_theme_color_override("font_color", p.cost_text)

	# Art frame
	var art := _make_style(p.body_bg.lightened(0.04), p.art_border, 4, 1)
	$CardBody/ArtFrame.add_theme_stylebox_override("panel", art)
	$CardBody/ArtFrame/ArtLabel.add_theme_color_override("font_color",
			p.art_border * Color(1, 1, 1, 0.9))

	# Name banner
	var name_style := StyleBoxFlat.new()
	name_style.bg_color = p.name_bg
	name_style.border_width_top = 1
	name_style.border_width_bottom = 1
	name_style.border_color = p.name_border
	$CardBody/NameBanner.add_theme_stylebox_override("panel", name_style)

	var name_label := $CardBody/NameBanner/CardName
	name_label.add_theme_color_override("font_color", p.name_text)
	name_label.add_theme_constant_override("outline_size", p.name_outline_size)
	name_label.add_theme_color_override("font_outline_color", p.name_outline)

	# Type label
	$CardBody/TypeLabel.add_theme_color_override("font_color", p.type_text)

	# Description box
	var desc := _make_style(p.body_bg.darkened(0.15), p.desc_border, 4, 1)
	desc.content_margin_left   = 6.0
	desc.content_margin_top    = 5.0
	desc.content_margin_right  = 6.0
	desc.content_margin_bottom = 5.0
	$CardBody/DescriptionBox.add_theme_stylebox_override("panel", desc)
	$CardBody/DescriptionBox/DescriptionText.add_theme_color_override(
			"default_color", p.desc_text)

	# Rarity strip — width varies by tier
	var strip := $CardBody/RarityStrip
	strip.offset_left  = float(p.rarity_strip_x0)
	strip.offset_right = float(p.rarity_strip_x1)
	var rar := _make_style(p.rarity_bg, p.rarity_border, 6, 1)
	strip.add_theme_stylebox_override("panel", rar)
	$CardBody/RarityStrip/RarityLabel.add_theme_color_override("font_color", p.rarity_text)
	# Expand label to fill new strip width
	$CardBody/RarityStrip/RarityLabel.offset_right = float(p.rarity_strip_x1 - p.rarity_strip_x0)

	# Pulsing glow for Mythic and Special
	if effective_rarity >= Rarity.MYTHIC:
		_start_pulse(p.shadow_base, p.shadow_peak)

func _start_pulse(base_sz: int, peak_sz: int) -> void:
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_method(_set_body_shadow, float(base_sz), float(peak_sz), 1.2) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_method(_set_body_shadow, float(peak_sz), float(base_sz), 1.2) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _set_body_shadow(sz: float) -> void:
	if _body_style:
		_body_style.shadow_size = int(sz)

func _make_style(bg: Color, border: Color, radius: int = 6, border_w: int = 2,
		shadow: Color = Color.TRANSPARENT, shadow_sz: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(border_w)
	s.border_color = border
	s.set_corner_radius_all(radius)
	s.shadow_color = shadow
	s.shadow_size = shadow_sz
	return s

# ── Label updates ──────────────────────────────────────────────────────────────

func _update_labels() -> void:
	$CardBody/CostBadge/CostLabel.text = str(card_cost)
	$CardBody/NameBanner/CardName.text = card_name
	$CardBody/TypeLabel.text = "— " + CARD_TYPE_LABELS[card_type] + " —"
	$CardBody/DescriptionBox/DescriptionText.text = card_description
	var rarity_text: String = RARITY_LABELS[effective_rarity]
	if upgraded:
		rarity_text += " +"
	$CardBody/RarityStrip/RarityLabel.text = rarity_text

# ── Hover animation (runtime only) ────────────────────────────────────────────

func _on_mouse_entered() -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", _base_scale * 1.08, 0.15)

func _on_mouse_exited() -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", _base_scale, 0.15)
