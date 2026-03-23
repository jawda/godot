@tool
class_name LevelUpScreen
extends CanvasLayer

## Level-up screen styled after a dark-fantasy RPG (Elden Ring-like).
## Static layout lives in level_up_screen.tscn.
## Stat rows are built in code since they are data-driven.
##
## Usage (runtime):
##   var screen = preload("res://characters/level/level_up_screen.tscn").instantiate()
##   add_child(screen)
##   screen.open(character_stats, level_system)

signal confirmed
signal cancelled

const STATS: Array[String] = [
	"strength", "dexterity", "vigor", "faith", "intelligence", "charisma"
]

## Color applied to the new-value label when a stat has been increased.
const COLOR_INCREASED := Color(0.45, 0.75, 1.0)
## Color applied when a stat would be decreased below its base.
const COLOR_DECREASED := Color(1.0, 0.4, 0.4)

@export var sword_icon: Texture2D

## Enable to keep the screen visible when running the scene standalone (F6).
@export var preview: bool = false

var _stats: CharacterStats
var _level_system: LevelSystem
var _pending: Dictionary = {}

# Per-stat node references (keyed by stat name)
var _current_labels: Dictionary = {}
var _new_labels: Dictionary = {}
var _dec_buttons: Dictionary = {}
var _inc_buttons: Dictionary = {}

@onready var _portrait: TextureRect  = $Panel/Margin/VBox/HeaderRow/Portrait
@onready var _character_name: Label  = $Panel/Margin/VBox/HeaderRow/HeaderText/CharacterName
@onready var _class_label: Label     = $Panel/Margin/VBox/HeaderRow/HeaderText/ClassLabel
@onready var _level_value: Label     = $Panel/Margin/VBox/InfoSection/LevelRow/LevelValue
@onready var _points_value: Label   = $Panel/Margin/VBox/InfoSection/PointsRow/PointsValue
@onready var _stat_list: VBoxContainer = $Panel/Margin/VBox/Tabs/Attributes/AttrVBox/StatList
@onready var _confirm_btn: Button   = $Panel/Margin/VBox/ButtonRow/ConfirmButton
@onready var _cancel_btn: Button    = $Panel/Margin/VBox/ButtonRow/CancelButton


func open(stats: CharacterStats, level_system: LevelSystem) -> void:
	_stats = stats
	_level_system = level_system
	for stat in STATS:
		_pending[stat] = 0
	show()
	_refresh()


func _ready() -> void:
	_build_stat_rows()
	$Panel/Margin/VBox/Tabs.set_tab_title(0, "Attribute Points")

	if Engine.is_editor_hint():
		_level_value.text = "1"
		_points_value.text = "3"
		return

	_confirm_btn.pressed.connect(_on_confirm_pressed)
	_cancel_btn.pressed.connect(_on_cancel_pressed)

	if not preview:
		hide()
	else:
		_level_value.text = "1"
		_points_value.text = "3"


func _build_stat_rows() -> void:
	for child in _stat_list.get_children():
		child.free()

	for stat in STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_stat_list.add_child(row)

		# Stat name — expands to fill available space
		var name_lbl := Label.new()
		name_lbl.text = stat.capitalize()
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		# Current base value
		var cur_lbl := Label.new()
		cur_lbl.custom_minimum_size = Vector2(32, 0)
		cur_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cur_lbl.text = "10"
		_current_labels[stat] = cur_lbl
		row.add_child(cur_lbl)

		# Sword icon separator
		var sword := TextureRect.new()
		sword.texture = sword_icon
		sword.custom_minimum_size = Vector2(16, 16)
		sword.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sword.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sword)

		# Decrease button
		var dec_btn := Button.new()
		dec_btn.text = "-"
		dec_btn.flat = true
		dec_btn.custom_minimum_size = Vector2(28, 28)
		if not Engine.is_editor_hint():
			dec_btn.pressed.connect(_on_dec_pressed.bind(stat))
		_dec_buttons[stat] = dec_btn
		row.add_child(dec_btn)

		# New (pending) value
		var new_lbl := Label.new()
		new_lbl.custom_minimum_size = Vector2(32, 0)
		new_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_lbl.text = "10"
		_new_labels[stat] = new_lbl
		row.add_child(new_lbl)

		# Increase button
		var inc_btn := Button.new()
		inc_btn.text = "+"
		inc_btn.flat = true
		inc_btn.custom_minimum_size = Vector2(28, 28)
		if not Engine.is_editor_hint():
			inc_btn.pressed.connect(_on_inc_pressed.bind(stat))
		_inc_buttons[stat] = inc_btn
		row.add_child(inc_btn)


func _refresh() -> void:
	var remaining := _level_system.skill_points - _pending_total()
	_character_name.text = _stats.base_stats.character_name
	_class_label.text = _stats.base_stats.character_class
	if _stats.base_stats.portrait:
		_portrait.texture = _stats.base_stats.portrait
	_level_value.text = str(_level_system.current_level)
	_points_value.text = str(remaining)

	for stat in STATS:
		var base_val: int = _stats.get(stat)
		var delta: int = _pending[stat]
		var new_val: int = base_val + delta

		_current_labels[stat].text = str(base_val)
		_new_labels[stat].text = str(new_val)

		if delta > 0:
			_new_labels[stat].modulate = COLOR_INCREASED
		elif delta < 0:
			_new_labels[stat].modulate = COLOR_DECREASED
		else:
			_new_labels[stat].modulate = Color.WHITE

		_dec_buttons[stat].disabled = delta <= 0
		_inc_buttons[stat].disabled = remaining <= 0 or new_val >= 99


func _pending_total() -> int:
	var total := 0
	for v in _pending.values():
		total += v
	return total


func _on_inc_pressed(stat: String) -> void:
	var remaining := _level_system.skill_points - _pending_total()
	if remaining > 0 and (_stats.get(stat) + _pending[stat]) < 99:
		_pending[stat] += 1
		_refresh()


func _on_dec_pressed(stat: String) -> void:
	if _pending[stat] > 0:
		_pending[stat] -= 1
		_refresh()


func _on_confirm_pressed() -> void:
	for stat in STATS:
		if _pending[stat] > 0:
			_stats.set(stat, _stats.get(stat) + _pending[stat])
			for i in _pending[stat]:
				_level_system.spend_skill_point()
	confirmed.emit()
	hide()


func _on_cancel_pressed() -> void:
	for stat in STATS:
		_pending[stat] = 0
	cancelled.emit()
	hide()
