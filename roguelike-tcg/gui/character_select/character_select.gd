class_name CharacterSelect
extends Control

# ── Scene references ──────────────────────────────────────────────────────────

const BATTLEFIELD_SCENE: PackedScene = preload("res://gui/battlefield.tscn")

## Add a new entry here each time a character is added.
const CHARACTER_RESOURCE_PATHS: Array[String] = [
	"res://player/characters/cleric.tres",
]

## Maps character_class → the visual scene that plays their animations.
const CHARACTER_VISUAL_SCENES: Dictionary = {
	"cleric": "res://player/characters/cleric_visual.tscn",
}

## Native size of one sprite frame in the cleric sheet (1500 × 810, 5 h × 3 v).
const SPRITE_FRAME_SIZE: Vector2i = Vector2i(300, 270)
## Displayed size for each character slot (0.67× scale of the frame).
const SLOT_DISPLAY_SIZE: Vector2 = Vector2(200, 180)

# ── Colours ───────────────────────────────────────────────────────────────────

const COLOR_SLOT_BG: Color           = Color(0.06, 0.03, 0.10, 0.90)
const COLOR_SLOT_BORDER_IDLE: Color  = Color(0.25, 0.12, 0.40, 0.50)
const COLOR_SLOT_BORDER_ACTIVE: Color = Color(0.75, 0.45, 1.00, 1.00)
const COLOR_DETAIL_BG: Color         = Color(0.08, 0.04, 0.13, 0.96)
const COLOR_DETAIL_BORDER: Color     = Color(0.50, 0.26, 0.78, 0.80)
const COLOR_NAME: Color              = Color(0.95, 0.88, 1.0, 1.0)
const COLOR_CLASS: Color             = Color(0.65, 0.48, 0.88, 1.0)
const COLOR_DESCRIPTION: Color       = Color(0.72, 0.65, 0.82, 1.0)
const COLOR_STAT_LABEL: Color        = Color(0.50, 0.44, 0.68, 1.0)
const COLOR_STAT_VALUE: Color        = Color(0.88, 0.82, 1.0, 1.0)

# ── Node references ───────────────────────────────────────────────────────────

@onready var _character_row: HBoxContainer = %CharacterRow
@onready var _detail_card: PanelContainer  = %DetailCard
@onready var _selected_name: Label         = %SelectedName
@onready var _selected_class: Label        = %SelectedClass
@onready var _selected_description: Label  = %SelectedDescription
@onready var _hp_value: Label              = %HPValue
@onready var _con_value: Label             = %ConValue
@onready var _faith_value: Label           = %FaithValue
@onready var _str_value: Label             = %StrValue
@onready var _begin_run_button: Button     = %BeginRun

# ── Runtime ───────────────────────────────────────────────────────────────────

var _selected_player_data: PlayerData = null
var _character_slots: Array[Panel] = []

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_begin_run_button.pressed.connect(_on_begin_run_pressed)
	_populate_characters()


# ── Character population ──────────────────────────────────────────────────────

func _populate_characters() -> void:
	for resource_path: String in CHARACTER_RESOURCE_PATHS:
		var player_data: PlayerData = load(resource_path) as PlayerData
		if player_data == null:
			push_warning("CharacterSelect: could not load PlayerData at %s" % resource_path)
			continue
		var slot: Panel = _build_character_slot(player_data)
		_character_row.add_child(slot)
		_character_slots.append(slot)


func _build_character_slot(player_data: PlayerData) -> Panel:
	var slot: Panel = Panel.new()
	slot.custom_minimum_size = SLOT_DISPLAY_SIZE
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.set_meta("player_data", player_data)
	slot.set_meta("normal_style", _make_slot_style(COLOR_SLOT_BORDER_IDLE))
	slot.set_meta("active_style", _make_slot_style(COLOR_SLOT_BORDER_ACTIVE))
	slot.add_theme_stylebox_override("panel", slot.get_meta("normal_style") as StyleBoxFlat)

	var viewport_container: SubViewportContainer = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(viewport_container)

	var viewport: SubViewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport_container.add_child(viewport)

	var visual_scene_path: String = CHARACTER_VISUAL_SCENES.get(player_data.character_class, "")
	if visual_scene_path != "":
		var visual_scene: PackedScene = load(visual_scene_path) as PackedScene
		if visual_scene != null:
			var visual_node: CharacterVisual = visual_scene.instantiate() as CharacterVisual
			# stretch=true forces the SubViewport to match the container size (SLOT_DISPLAY_SIZE),
			# so we position and scale the sprite to fit that canvas, not the native frame size.
			var scale_factor: float = minf(
				SLOT_DISPLAY_SIZE.x / float(SPRITE_FRAME_SIZE.x),
				SLOT_DISPLAY_SIZE.y / float(SPRITE_FRAME_SIZE.y)
			)
			visual_node.position = Vector2(SLOT_DISPLAY_SIZE.x * 0.5, SLOT_DISPLAY_SIZE.y * 0.5)
			visual_node.scale    = Vector2(scale_factor, scale_factor)
			viewport.add_child(visual_node)

	slot.gui_input.connect(func(input_event: InputEvent) -> void:
		if input_event is InputEventMouseButton \
				and input_event.button_index == MOUSE_BUTTON_LEFT \
				and input_event.pressed:
			_on_character_clicked(slot, player_data)
	)

	return slot


# ── Selection ─────────────────────────────────────────────────────────────────

func _on_character_clicked(selected_slot: Panel, player_data: PlayerData) -> void:
	_selected_player_data = player_data

	for slot: Panel in _character_slots:
		var style_key: String = "active_style" if slot == selected_slot else "normal_style"
		slot.add_theme_stylebox_override("panel", slot.get_meta(style_key) as StyleBoxFlat)

	_populate_detail_card(player_data)
	_detail_card.show()
	_begin_run_button.show()


func _populate_detail_card(player_data: PlayerData) -> void:
	_selected_name.text = player_data.character_name
	_selected_class.text = player_data.character_class.capitalize()
	_selected_description.text = player_data.character_description

	var max_hp: int = player_data.base_max_health + \
			player_data.constitution * CombatPlayer.HP_PER_CONSTITUTION
	_hp_value.text = str(max_hp)
	_con_value.text = str(player_data.constitution)
	_faith_value.text = str(player_data.faith)
	_str_value.text = str(player_data.strength)


# ── Scene transition ──────────────────────────────────────────────────────────

func _on_begin_run_pressed() -> void:
	if _selected_player_data == null:
		return
	var battlefield: Battlefield = BATTLEFIELD_SCENE.instantiate() as Battlefield
	battlefield.player_data = _selected_player_data
	get_tree().root.add_child(battlefield)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = battlefield


# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_slot_style(border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_SLOT_BG
	style.set_border_width_all(2)
	style.border_color = border_color
	style.set_corner_radius_all(6)
	return style
