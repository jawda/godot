class_name LabelChip
extends Button
## One answer in the word bank. Click to pick it up, or drag it onto a blank.

signal chosen(chip: LabelChip)

var answer_text: String = ""
## The blank this chip currently sits in, or null while it is in the bank.
var placed_in: DiagramBlank = null


func _ready() -> void:
	pressed.connect(func() -> void: chosen.emit(self))


func set_answer(answer: String) -> void:
	answer_text = answer
	text = answer


func set_selected(is_selected: bool) -> void:
	theme_type_variation = &"LabelChipSelected" if is_selected else &"LabelChip"


## Godot calls this when a drag starts on the chip; what it returns is handed to the
## drop target's _can_drop_data and _drop_data.
func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview: Button = Button.new()
	preview.text = answer_text
	preview.theme_type_variation = &"LabelChipSelected"
	set_drag_preview(preview)
	return {"chip": self}
