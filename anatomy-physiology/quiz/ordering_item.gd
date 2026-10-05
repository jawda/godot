class_name OrderingItem
extends PanelContainer
## One draggable-by-buttons entry in an ordering question.

signal move_requested(item: OrderingItem, direction: int)

var item_text: String = ""

# ── Node references ──
@onready var _position: Label = $Layout/Position
@onready var _text: Label = $Layout/Text
@onready var _move_up: Button = $Layout/MoveUp
@onready var _move_down: Button = $Layout/MoveDown


func _ready() -> void:
	_move_up.pressed.connect(func() -> void: move_requested.emit(self, -1))
	_move_down.pressed.connect(func() -> void: move_requested.emit(self, 1))


func set_item_text(text: String) -> void:
	item_text = text
	_text.text = text


func set_position_number(position_number: int, item_count: int) -> void:
	_position.text = str(position_number)
	_move_up.disabled = position_number == 1
	_move_down.disabled = position_number == item_count


## Locks the row and colours it by whether it landed in the right slot.
func reveal(is_correct: bool, correct_position: int) -> void:
	_move_up.visible = false
	_move_down.visible = false
	theme_type_variation = &"OrderingCorrect" if is_correct else &"OrderingWrong"
	if not is_correct:
		_text.text = "%s   (belongs at %d)" % [item_text, correct_position]
