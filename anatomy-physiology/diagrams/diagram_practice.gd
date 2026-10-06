class_name DiagramPractice
extends MarginContainer
## The Diagrams tab: label a figure whose printed labels are hidden, either by placing
## answers from a word bank (click a label then a blank, or drag) or by typing them.
## The first Check of each attempt is the one that counts toward the best score; after
## that you can fix the misses and check again, or reveal the answers.

const CHIP_SCENE: PackedScene = preload("res://diagrams/label_chip.tscn")

var _diagrams: Array[LabeledDiagram] = []
var _diagram_index: int = 0
var _is_typing: bool = false
var _blanks: Array[DiagramBlank] = []
var _chips: Array[LabelChip] = []
var _selected_chip: LabelChip = null
## True once Check has been pressed this attempt, so later checks don't change the best score.
var _has_scored_attempt: bool = false
var _is_revealed: bool = false

# ── Node references ──
@onready var _session: VBoxContainer = $Session
@onready var _previous: Button = $Session/Toolbar/Previous
@onready var _picker: OptionButton = $Session/Toolbar/Picker
@onready var _next: Button = $Session/Toolbar/Next
@onready var _zoom_out: Button = $Session/Toolbar/Zoom/ZoomOut
@onready var _zoom_level: Label = $Session/Toolbar/Zoom/ZoomLevel
@onready var _zoom_in: Button = $Session/Toolbar/Zoom/ZoomIn
@onready var _fit: Button = $Session/Toolbar/Zoom/Fit
@onready var _word_bank_mode: Button = $Session/Toolbar/Mode/WordBank
@onready var _typing_mode: Button = $Session/Toolbar/Mode/Typing
@onready var _board: DiagramBoard = $Session/Workspace/Board
@onready var _prompt: Label = $Session/Workspace/Sidebar/Prompt
@onready var _bank_hint: Label = $Session/Workspace/Sidebar/BankHint
@onready var _bank: ScrollContainer = $Session/Workspace/Sidebar/Bank
@onready var _chip_list: HFlowContainer = $Session/Workspace/Sidebar/Bank/Chips
@onready var _typing_hint: Label = $Session/Workspace/Sidebar/TypingHint
@onready var _credit: Label = $Session/Workspace/Sidebar/Credit
@onready var _status: Label = $Session/Actions/Status
@onready var _start_over: Button = $Session/Actions/StartOver
@onready var _reveal: Button = $Session/Actions/Reveal
@onready var _check: Button = $Session/Actions/Check
@onready var _empty: Label = $Empty


func _ready() -> void:
	_previous.pressed.connect(func() -> void: _open_diagram(_diagram_index - 1))
	_next.pressed.connect(func() -> void: _open_diagram(_diagram_index + 1))
	_picker.item_selected.connect(_open_diagram)
	_zoom_in.pressed.connect(_board.zoom_in)
	_zoom_out.pressed.connect(_board.zoom_out)
	_fit.pressed.connect(_board.fit_to_canvas)
	_board.zoom_changed.connect(_on_zoom_changed)
	_word_bank_mode.pressed.connect(_set_typing.bind(false))
	_typing_mode.pressed.connect(_set_typing.bind(true))
	_start_over.pressed.connect(_start_attempt)
	_reveal.pressed.connect(_reveal_answers)
	_check.pressed.connect(_check_answers)
	_board.blank_clicked.connect(_on_blank_clicked)
	_board.chip_dropped.connect(_place_chip)
	_board.entry_submitted.connect(_focus_after)
	_board.entry_edited.connect(func(_blank: DiagramBlank) -> void: _update_status())


func load_diagrams(diagrams: Array[LabeledDiagram]) -> void:
	_diagrams = diagrams
	_session.visible = not diagrams.is_empty()
	_empty.visible = diagrams.is_empty()
	if diagrams.is_empty():
		return
	_diagram_index = 0
	_refresh_picker()
	_open_diagram(0)


func has_diagrams() -> bool:
	return not _diagrams.is_empty()


func _open_diagram(diagram_index: int) -> void:
	_diagram_index = clampi(diagram_index, 0, _diagrams.size() - 1)
	_picker.select(_diagram_index)
	_previous.disabled = _diagram_index == 0
	_next.disabled = _diagram_index == _diagrams.size() - 1
	var diagram: LabeledDiagram = _diagrams[_diagram_index]
	_prompt.text = diagram.prompt
	_prompt.visible = not diagram.prompt.is_empty()
	_credit.text = diagram.credit
	_start_attempt()


func _on_zoom_changed(zoom: float, can_zoom_in: bool, can_zoom_out: bool) -> void:
	_zoom_level.text = "%d%%" % roundi(zoom * 100.0)
	_zoom_in.disabled = not can_zoom_in
	_zoom_out.disabled = not can_zoom_out


func _set_typing(is_typing: bool) -> void:
	_word_bank_mode.button_pressed = not is_typing
	_typing_mode.button_pressed = is_typing
	if is_typing == _is_typing:
		return
	_is_typing = is_typing
	_start_attempt()


## Clears every blank and deals a fresh word bank.
func _start_attempt() -> void:
	var diagram: LabeledDiagram = _diagrams[_diagram_index]
	_has_scored_attempt = false
	_is_revealed = false
	_selected_chip = null
	_blanks = _board.show_diagram(diagram, _is_typing)
	_build_chips(diagram)
	_bank_hint.visible = not _is_typing
	_bank.visible = not _is_typing
	_typing_hint.visible = _is_typing
	_check.disabled = false
	_reveal.disabled = false
	_update_status()
	if _is_typing and not _blanks.is_empty():
		_blanks[0].focus_entry()


## Chips differ per diagram, so they are made here. Alphabetical, so a long bank is
## easy to scan; the order gives nothing away because the blanks aren't in that order.
func _build_chips(diagram: LabeledDiagram) -> void:
	for chip: LabelChip in _chips:
		chip.queue_free()
	_chips.clear()
	if _is_typing:
		return
	var answers: Array[String] = []
	for diagram_label: DiagramLabel in diagram.labels:
		answers.append(diagram_label.text)
	answers.sort_custom(func(first: String, second: String) -> bool: return first.naturalnocasecmp_to(second) < 0)
	for answer: String in answers:
		var chip: LabelChip = CHIP_SCENE.instantiate()
		_chip_list.add_child(chip)
		chip.set_answer(answer)
		chip.chosen.connect(_on_chip_chosen)
		_chips.append(chip)


func _on_chip_chosen(chip: LabelChip) -> void:
	_select_chip(null if chip == _selected_chip else chip)


func _select_chip(chip: LabelChip) -> void:
	_selected_chip = chip
	for candidate: LabelChip in _chips:
		candidate.set_selected(candidate == chip)
	for blank: DiagramBlank in _blanks:
		blank.set_targeted(chip != null and not blank.is_locked())


func _on_blank_clicked(blank: DiagramBlank) -> void:
	if _is_typing:
		blank.focus_entry()
		return
	if blank.is_locked():
		return
	if _selected_chip != null:
		_place_chip(blank, _selected_chip)
	elif blank.placed_chip != null:
		# Clicking a filled blank with nothing picked up sends its label back to the bank.
		_return_chip(blank.placed_chip)
		_update_status()


## Puts a chip in a blank. A chip already in that blank swaps places with it, so
## dragging between two filled blanks exchanges them.
func _place_chip(blank: DiagramBlank, chip: LabelChip) -> void:
	if blank.is_locked() or blank.placed_chip == chip:
		_select_chip(null)
		return
	var source_blank: DiagramBlank = chip.placed_in
	var displaced_chip: LabelChip = blank.placed_chip
	if source_blank != null:
		source_blank.hold_chip(null)
	if displaced_chip != null:
		if source_blank != null:
			source_blank.hold_chip(displaced_chip)
			displaced_chip.placed_in = source_blank
		else:
			_return_chip(displaced_chip)
	blank.hold_chip(chip)
	chip.placed_in = blank
	chip.visible = false
	_select_chip(null)
	_update_status()


func _return_chip(chip: LabelChip) -> void:
	if chip.placed_in != null and chip.placed_in.placed_chip == chip:
		chip.placed_in.hold_chip(null)
	chip.placed_in = null
	chip.visible = true


## Enter in a typed blank moves on to the next open one.
func _focus_after(blank: DiagramBlank) -> void:
	var start_index: int = _blanks.find(blank)
	for offset: int in range(1, _blanks.size()):
		var candidate: DiagramBlank = _blanks[(start_index + offset) % _blanks.size()]
		if not candidate.is_locked():
			candidate.focus_entry()
			return


func _check_answers() -> void:
	_select_chip(null)
	var correct_count: int = 0
	var spelling_slips: int = 0
	for blank: DiagramBlank in _blanks:
		if blank.is_locked():
			correct_count += 1
			continue
		var is_correct: bool = false
		if _is_typing:
			var grade: DiagramLabel.Grade = blank.label.grade_typed(blank.placed_text())
			is_correct = grade != DiagramLabel.Grade.WRONG
			if grade == DiagramLabel.Grade.CLOSE:
				spelling_slips += 1
				blank.show_corrected_spelling()
		else:
			is_correct = blank.label.is_placed_correctly(blank.placed_text())
		blank.set_state(DiagramBlank.State.CORRECT if is_correct else DiagramBlank.State.WRONG)
		if is_correct:
			correct_count += 1
	var diagram: LabeledDiagram = _diagrams[_diagram_index]
	if not _has_scored_attempt:
		_has_scored_attempt = true
		StudyProgress.record_diagram_score(diagram.id, float(correct_count) / _blanks.size())
		_refresh_picker()
	var result: String = "%d of %d correct" % [correct_count, _blanks.size()]
	if spelling_slips > 0:
		result += "  ·  %d spelling fixed, hover to see what you typed" % spelling_slips
	if correct_count == _blanks.size():
		result += "  ·  all labeled!"
		_check.disabled = true
		_reveal.disabled = true
	else:
		result += "  ·  fix the red ones and check again, or show the answers"
	_status.text = result


func _reveal_answers() -> void:
	_select_chip(null)
	_is_revealed = true
	for blank: DiagramBlank in _blanks:
		if blank.is_locked():
			continue
		if blank.placed_chip != null:
			_return_chip(blank.placed_chip)
		blank.reveal()
	for chip: LabelChip in _chips:
		chip.visible = false
	_check.disabled = true
	_reveal.disabled = true
	_status.text = "Answers shown in orange. Start over to try it again."


func _update_status() -> void:
	if _is_revealed:
		return
	var filled_count: int = 0
	for blank: DiagramBlank in _blanks:
		if blank.is_filled():
			filled_count += 1
	var best_score: float = StudyProgress.best_diagram_score(_diagrams[_diagram_index].id)
	var best_text: String = "" if best_score < 0.0 else "  ·  best first try %d%%" % roundi(best_score * 100.0)
	_status.text = "%d of %d labeled%s" % [filled_count, _blanks.size(), best_text]


func _refresh_picker() -> void:
	_picker.clear()
	for diagram_index: int in _diagrams.size():
		var diagram: LabeledDiagram = _diagrams[diagram_index]
		var best_score: float = StudyProgress.best_diagram_score(diagram.id)
		var score_text: String = "" if best_score < 0.0 else "   ·   best %d%%" % roundi(best_score * 100.0)
		_picker.add_item("%d.  %s%s" % [diagram_index + 1, diagram.title, score_text], diagram_index)
	_picker.select(_diagram_index)
