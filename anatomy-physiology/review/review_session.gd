class_name ReviewSession
extends MarginContainer
## Cross-module practice: a random mixed set, or every question currently marked as missed.

signal back_requested

const MIXED_REVIEW_SIZE: int = 20

# ── Node references ──
@onready var _back: Button = $Layout/Header/Back
@onready var _title: Label = $Layout/Header/Titles/Title
@onready var _runner: QuizRunner = $Layout/Quiz/Runner


func _ready() -> void:
	_back.pressed.connect(back_requested.emit)


## Draws from modules the student has started; falls back to everything before any study.
func start_mixed_review() -> void:
	var pool: Array[QuizQuestion] = []
	for module: StudyModule in ContentLibrary.modules:
		if StudyProgress.has_started(module):
			pool.append_array(module.quiz_questions)
	var source_note: String = "from the modules you have started"
	if pool.is_empty():
		pool = ContentLibrary.all_questions()
		source_note = "from every module"
	pool.shuffle()
	_title.text = "Mixed review: %d questions %s" % [mini(MIXED_REVIEW_SIZE, pool.size()), source_note]
	_runner.start(pool.slice(0, MIXED_REVIEW_SIZE))


func start_missed_review() -> void:
	var missed: Array[QuizQuestion] = []
	for question_id: String in StudyProgress.missed_question_ids():
		var question: QuizQuestion = ContentLibrary.get_question(question_id)
		if question != null:
			missed.append(question)
	_title.text = "Missed questions (%d)" % missed.size()
	_runner.start(missed)
