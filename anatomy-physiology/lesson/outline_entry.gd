class_name OutlineEntry
extends Button
## One row of the lesson outline: an icon showing done / current / not yet, then the title.

signal chosen(section_index: int)

const DONE_ICON: Texture2D = preload("res://theme/icons/section_done.svg")
const TODO_ICON: Texture2D = preload("res://theme/icons/section_todo.svg")
const CURRENT_ICON: Texture2D = preload("res://theme/icons/section_current.svg")

var section_index: int = 0


func _ready() -> void:
	pressed.connect(func() -> void: chosen.emit(section_index))


func set_state(is_read: bool, is_current: bool) -> void:
	theme_type_variation = &"OutlineEntryCurrent" if is_current else &"OutlineEntry"
	if is_read:
		icon = DONE_ICON
	elif is_current:
		icon = CURRENT_ICON
	else:
		icon = TODO_ICON
