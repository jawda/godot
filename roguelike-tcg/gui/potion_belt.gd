class_name PotionBelt
extends HBoxContainer

## Three-slot consumable belt shown during combat.
## Call setup() with the run's consumable list.
## Emits consumable_used when a slot is clicked; the caller is responsible
## for removing the item from run inventory.

signal consumable_used(consumable: ConsumableData, slot_index: int)

# ── Constants ──────────────────────────────────────────────────────────────────

const SLOT_SIZE: Vector2 = Vector2(40.0, 40.0)
const SLOT_COUNT: int    = 3

const EMPTY_FILL: Color   = Color(0.10, 0.07, 0.15, 1.0)
const EMPTY_BORDER: Color = Color(0.28, 0.20, 0.38, 0.60)

const EFFECT_COLORS: Dictionary = {
	ConsumableEffect.EffectType.RESTORE_HP:           Color(0.25, 0.78, 0.35, 1.0),
	ConsumableEffect.EffectType.DEAL_DAMAGE:          Color(0.90, 0.28, 0.22, 1.0),
	ConsumableEffect.EffectType.GAIN_STAT:            Color(0.90, 0.72, 0.18, 1.0),
	ConsumableEffect.EffectType.GAIN_BLOCK:           Color(0.22, 0.55, 0.90, 1.0),
	ConsumableEffect.EffectType.DRAW_CARDS:           Color(0.65, 0.32, 0.90, 1.0),
	ConsumableEffect.EffectType.BONUS_ATTACK_DAMAGE:  Color(0.90, 0.48, 0.18, 1.0),
	ConsumableEffect.EffectType.SCALE_HEALS:          Color(0.42, 0.90, 0.42, 1.0),
	ConsumableEffect.EffectType.EXTRA_CARDS_PER_TURN: Color(0.78, 0.52, 0.90, 1.0),
	ConsumableEffect.EffectType.DAMAGE_PER_TURN:      Color(0.60, 0.12, 0.12, 1.0),
}

## Margin between the bottom of the hover card and the top of the hovered slot.
const HOVER_GAP: float = 8.0

# ── Node references ────────────────────────────────────────────────────────────

@onready var _slot_1: Button          = $Slot1
@onready var _slot_2: Button          = $Slot2
@onready var _slot_3: Button          = $Slot3
@onready var _hover_card: PanelContainer = $HoverCard
@onready var _hover_name: Label          = $HoverCard/Contents/ItemName
@onready var _hover_description: Label   = $HoverCard/Contents/ItemDescription

# ── State ──────────────────────────────────────────────────────────────────────

var _consumables: Array[ConsumableData]     = [null, null, null]
var _is_interactive: bool                   = false
var _slot_buttons: Array[Button]            = []
var _slot_base_styles: Array[StyleBoxFlat]  = []
var _slot_hover_styles: Array[StyleBoxFlat] = []

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_slot_buttons = [_slot_1, _slot_2, _slot_3]
	for slot_index: int in SLOT_COUNT:
		var base_style: StyleBoxFlat  = _make_circle_style()
		var hover_style: StyleBoxFlat = _make_circle_style()
		var focus_style: StyleBoxFlat = StyleBoxFlat.new()
		var slot_button: Button = _slot_buttons[slot_index]
		slot_button.custom_minimum_size = SLOT_SIZE
		slot_button.add_theme_stylebox_override("normal",   base_style)
		slot_button.add_theme_stylebox_override("disabled", base_style)
		slot_button.add_theme_stylebox_override("hover",    hover_style)
		slot_button.add_theme_stylebox_override("pressed",  hover_style)
		slot_button.add_theme_stylebox_override("focus",    focus_style)
		slot_button.pressed.connect(_on_slot_pressed.bind(slot_index))
		slot_button.mouse_entered.connect(_on_slot_mouse_entered.bind(slot_index))
		slot_button.mouse_exited.connect(_on_slot_mouse_exited)
		_slot_base_styles.append(base_style)
		_slot_hover_styles.append(hover_style)
	_hover_card.hide()
	_refresh_visuals()

# ── Public API ─────────────────────────────────────────────────────────────────

func setup(consumables: Array[ConsumableData]) -> void:
	_consumables = [null, null, null]
	for slot_index: int in mini(consumables.size(), SLOT_COUNT):
		_consumables[slot_index] = consumables[slot_index]
	_refresh_visuals()

func set_interactive(enabled: bool) -> void:
	_is_interactive = enabled
	if not enabled:
		_hover_card.hide()
	_refresh_visuals()

# ── Visuals ────────────────────────────────────────────────────────────────────

func _make_circle_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(int(SLOT_SIZE.x * 0.5))
	style.set_border_width_all(2)
	return style

func _refresh_visuals() -> void:
	if _slot_buttons.is_empty():
		return
	for slot_index: int in SLOT_COUNT:
		_refresh_slot(slot_index)

func _refresh_slot(slot_index: int) -> void:
	var consumable: ConsumableData = _consumables[slot_index]
	var slot_button: Button        = _slot_buttons[slot_index]
	var base_style: StyleBoxFlat   = _slot_base_styles[slot_index]
	var hover_style: StyleBoxFlat  = _slot_hover_styles[slot_index]

	if consumable == null:
		base_style.bg_color      = EMPTY_FILL
		base_style.border_color  = EMPTY_BORDER
		hover_style.bg_color     = EMPTY_FILL
		hover_style.border_color = EMPTY_BORDER
		slot_button.disabled     = true
		return

	var item_color: Color = _color_for_consumable(consumable)
	if _is_interactive:
		base_style.bg_color      = item_color.darkened(0.35)
		base_style.border_color  = item_color
		hover_style.bg_color     = item_color.darkened(0.15)
		hover_style.border_color = item_color.lightened(0.20)
	else:
		base_style.bg_color      = item_color.darkened(0.55)
		base_style.border_color  = item_color.darkened(0.30)
		hover_style.bg_color     = item_color.darkened(0.55)
		hover_style.border_color = item_color.darkened(0.30)
	slot_button.disabled = not _is_interactive

func _color_for_consumable(consumable: ConsumableData) -> Color:
	if consumable.effects.is_empty():
		return Color(0.55, 0.55, 0.55, 1.0)
	var primary_effect_type: ConsumableEffect.EffectType = consumable.effects[0].effect_type
	return EFFECT_COLORS.get(primary_effect_type, Color(0.55, 0.55, 0.55, 1.0))

# ── Hover card ─────────────────────────────────────────────────────────────────

func _on_slot_mouse_entered(slot_index: int) -> void:
	var consumable: ConsumableData = _consumables[slot_index]
	if consumable == null:
		return
	_hover_name.text        = consumable.item_name
	_hover_description.text = consumable.description
	_hover_card.show()
	# Wait one frame for the panel to lay out so its size is accurate.
	await get_tree().process_frame
	if not _hover_card.visible:
		return
	_reposition_hover_card(_slot_buttons[slot_index])

func _on_slot_mouse_exited() -> void:
	_hover_card.hide()

func _reposition_hover_card(slot_button: Button) -> void:
	var viewport_size: Vector2  = get_viewport().get_visible_rect().size
	var slot_global: Vector2    = slot_button.global_position
	var card_size: Vector2      = _hover_card.size

	# Centre the card horizontally over the slot, appear above it.
	var card_x: float = slot_global.x + slot_button.size.x * 0.5 - card_size.x * 0.5
	var card_y: float = slot_global.y - card_size.y - HOVER_GAP

	# Keep within screen bounds.
	card_x = clampf(card_x, 4.0, viewport_size.x - card_size.x - 4.0)
	card_y = clampf(card_y, 4.0, viewport_size.y - card_size.y - 4.0)

	_hover_card.global_position = Vector2(card_x, card_y)

# ── Input ──────────────────────────────────────────────────────────────────────

func _on_slot_pressed(slot_index: int) -> void:
	var consumable: ConsumableData = _consumables[slot_index]
	if consumable == null:
		return
	_hover_card.hide()
	_consumables[slot_index] = null
	_refresh_slot(slot_index)
	consumable_used.emit(consumable, slot_index)
