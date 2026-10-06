class_name DiagramBlank
extends PanelContainer
## Covers one printed label on a diagram. In word-bank mode it holds a LabelChip; in
## typing mode it holds a text entry. The practice screen decides what clicks and drops
## mean; the blank only reports them.

signal clicked(blank: DiagramBlank)
signal chip_dropped(blank: DiagramBlank, chip: LabelChip)
signal entry_submitted(blank: DiagramBlank)
signal entry_edited(blank: DiagramBlank)

enum State { OPEN, CORRECT, WRONG, REVEALED }

const STYLE_BY_STATE: Dictionary[State, StringName] = {
	State.OPEN: &"DiagramBlank",
	State.CORRECT: &"DiagramBlankCorrect",
	State.WRONG: &"DiagramBlankWrong",
	State.REVEALED: &"DiagramBlankRevealed",
}

var label: DiagramLabel = null
var placed_chip: LabelChip = null
var state: State = State.OPEN
var _is_typing: bool = false
var _is_targeted: bool = false
## Largest text size that matches the printed label; long answers shrink below it.
var _base_font_size: int = 14

# ── Node references ──
@onready var _answer: Label = $Answer
@onready var _entry: LineEdit = $Entry


func _ready() -> void:
	_entry.text_submitted.connect(func(_submitted: String) -> void: entry_submitted.emit(self))
	_entry.text_changed.connect(_on_entry_changed)


func setup(diagram_label: DiagramLabel, is_typing: bool) -> void:
	label = diagram_label
	_is_typing = is_typing
	_answer.visible = not is_typing
	_entry.visible = is_typing
	_entry.text = ""
	_answer.text = ""
	tooltip_text = ""
	placed_chip = null
	set_state(State.OPEN)


## rect is in the board's stage coordinates; font_size matches the printed label.
func place_at(rect: Rect2, font_size: int) -> void:
	position = rect.position
	custom_minimum_size = rect.size
	size = rect.size
	_base_font_size = font_size
	_fit_text()


func placed_text() -> String:
	if _is_typing:
		return _entry.text
	return placed_chip.answer_text if placed_chip != null else ""


func is_filled() -> bool:
	return not placed_text().strip_edges().is_empty()


func is_locked() -> bool:
	return state == State.CORRECT or state == State.REVEALED


func hold_chip(chip: LabelChip) -> void:
	placed_chip = chip
	_answer.text = chip.answer_text if chip != null else ""
	_fit_text()
	if state == State.WRONG:
		set_state(State.OPEN)


func set_state(new_state: State) -> void:
	state = new_state
	_entry.editable = not is_locked()
	if _is_typing:
		# A one-line entry would cut off a long answer, so a finished blank shows its
		# text wrapped like the word-bank blanks do.
		_entry.visible = not is_locked()
		_answer.visible = is_locked()
		_answer.text = _entry.text if is_locked() else ""
		_fit_text()
	_refresh_style()


## Highlights open blanks while a chip is picked up, to show where it can go.
func set_targeted(is_targeted: bool) -> void:
	_is_targeted = is_targeted
	_refresh_style()


## Shows the right answer in place of whatever was there.
func reveal() -> void:
	if _is_typing:
		_entry.text = label.text
	else:
		_answer.text = label.text
		_fit_text()
	set_state(State.REVEALED)


## A typed answer with a small slip counts, but the blank shows the right spelling.
func show_corrected_spelling() -> void:
	tooltip_text = "You typed \"%s\"" % _entry.text
	_entry.text = label.text


func focus_entry() -> void:
	if _is_typing and not is_locked():
		_entry.grab_focus()


## Picks the biggest text size, up to the printed label's, at which the answer fits the
## box without breaking a word. Typing mode sizes for the right answer on one line.
func _fit_text() -> void:
	var font: Font = _answer.get_theme_font(&"font")
	var available: Vector2 = custom_minimum_size - get_theme_stylebox(&"panel").get_minimum_size()
	# The printed label's box has a little padding, so the text may use some of it.
	available.y += 4.0
	var font_size: int = _base_font_size
	if _entry.visible:
		while font_size > DiagramBoard.MINIMUM_FONT_SIZE and (font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x > available.x or font.get_height(font_size) > available.y):
			font_size -= 1
	elif not _answer.text.is_empty():
		var break_flags: int = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
		while font_size > DiagramBoard.MINIMUM_FONT_SIZE:
			var wrapped: Vector2 = font.get_multiline_string_size(_answer.text, HORIZONTAL_ALIGNMENT_CENTER, available.x, font_size, -1, break_flags)
			if wrapped.x <= available.x and wrapped.y <= available.y:
				break
			font_size -= 1
	_answer.add_theme_font_size_override("font_size", font_size)
	_entry.add_theme_font_size_override("font_size", font_size)


func _on_entry_changed(_changed: String) -> void:
	if state == State.WRONG:
		set_state(State.OPEN)
	else:
		_refresh_style()
	entry_edited.emit(self)


func _refresh_style() -> void:
	if state == State.OPEN and _is_targeted:
		theme_type_variation = &"DiagramBlankTarget"
	elif state == State.OPEN and is_filled():
		theme_type_variation = &"DiagramBlankFilled"
	else:
		theme_type_variation = STYLE_BY_STATE[state]


func _gui_input(event: InputEvent) -> void:
	var button_event: InputEventMouseButton = event as InputEventMouseButton
	if button_event != null and button_event.button_index == MOUSE_BUTTON_LEFT and not button_event.pressed:
		clicked.emit(self)
		accept_event()


# Drag and drop: Godot asks the control under the pointer whether it accepts the
# dragged data (_can_drop_data), then hands it over (_drop_data).

func _get_drag_data(_at_position: Vector2) -> Variant:
	if _is_typing or placed_chip == null or is_locked():
		return null
	var preview: Button = Button.new()
	preview.text = placed_chip.answer_text
	preview.theme_type_variation = &"LabelChipSelected"
	set_drag_preview(preview)
	return {"chip": placed_chip}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return not _is_typing and not is_locked() and data is Dictionary and (data as Dictionary).has("chip")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	chip_dropped.emit(self, (data as Dictionary)["chip"])
