class_name ModuleTile
extends Button
## A clickable card on the home screen representing one module.

signal chosen(module: StudyModule)

var _module: StudyModule = null

# ── Node references ──
@onready var _number: Label = $Content/Stack/Number
@onready var _title: Label = $Content/Stack/Title
@onready var _summary: Label = $Content/Stack/Summary
@onready var _mastery: ProgressBar = $Content/Stack/Mastery
@onready var _mastery_caption: Label = $Content/Stack/MasteryCaption


func _ready() -> void:
	pressed.connect(func() -> void: chosen.emit(_module))


func show_module(module: StudyModule) -> void:
	_module = module
	_number.text = "MODULE %d" % module.order
	_title.text = module.title
	_summary.text = module.summary
	tooltip_text = module.summary
	refresh_progress()


func refresh_progress() -> void:
	var mastery: float = StudyProgress.question_mastery(_module)
	_mastery.value = mastery
	if not StudyProgress.has_started(_module):
		_mastery_caption.text = "Not started"
		return
	var known_count: int = StudyProgress.known_flashcard_count(_module)
	var read_count: int = StudyProgress.read_section_count(_module)
	_mastery_caption.text = "Read %d/%d  ·  Cards %d/%d  ·  Quiz %d%%" % [
		read_count, _module.lesson_sections.size(), known_count, _module.flashcards.size(),
		roundi(mastery * 100.0)]
