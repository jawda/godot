class_name QuizRunner
extends MarginContainer
## Runs a list of questions one at a time with immediate feedback, then shows results.
## Used both for a single module's quiz and for cross-module review sessions.

signal session_finished(correct_count: int, question_count: int)

const CHOICE_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9]

## The set passed to start(), kept so "Retake the whole quiz" can rerun it.
var _full_questions: Array[QuizQuestion] = []
var _full_score_module_id: String = ""
var _questions: Array[QuizQuestion] = []
## Module whose best score this run updates; empty for reviews and retry-missed runs.
var _score_module_id: String = ""
var _question_index: int = 0
var _correct_count: int = 0
var _missed: Array[QuizQuestion] = []
var _is_answered: bool = false
## Display slot -> index into question.choices (multiple choice is shuffled per showing).
var _choice_order: Array[int] = []
var _choice_buttons: Array[Button] = []

# ── Node references ──
@onready var _session: VBoxContainer = $Session
@onready var _position: Label = $Session/Status/Position
@onready var _score: Label = $Session/Status/Score
@onready var _progress: ProgressBar = $Session/Progress
@onready var _prompt: Label = $Session/Prompt
@onready var _answers: ScrollContainer = $Session/Answers
@onready var _choices: VBoxContainer = $Session/Answers/AnswerArea/Choices
@onready var _ordering: OrderingBoard = $Session/Answers/AnswerArea/Ordering
@onready var _feedback: PanelContainer = $Session/Answers/AnswerArea/Feedback
@onready var _verdict: Label = $Session/Answers/AnswerArea/Feedback/FeedbackBody/Verdict
@onready var _explanation: RichTextLabel = $Session/Answers/AnswerArea/Feedback/FeedbackBody/Explanation
@onready var _key_hint: Label = $Session/Actions/KeyHint
@onready var _advance: Button = $Session/Actions/Advance
@onready var _results: QuizResults = $Results


func _ready() -> void:
	_advance.pressed.connect(_on_advance_pressed)
	_results.retry_requested.connect(func() -> void: start(_full_questions, _full_score_module_id))
	_results.retry_missed_requested.connect(func() -> void: _run(_missed.duplicate(), ""))


## Pass score_module_id to record a best score for that module when the run completes.
func start(questions: Array[QuizQuestion], score_module_id: String = "") -> void:
	_full_questions = questions.duplicate()
	_full_score_module_id = score_module_id
	_run(questions, score_module_id)


func _run(questions: Array[QuizQuestion], score_module_id: String) -> void:
	_questions = questions.duplicate()
	_questions.shuffle()
	_score_module_id = score_module_id
	_question_index = 0
	_correct_count = 0
	_missed.clear()
	_session.visible = true
	_results.visible = false
	if _questions.is_empty():
		_finish_session()
		return
	_show_question()


func _show_question() -> void:
	var question: QuizQuestion = _questions[_question_index]
	_is_answered = false
	_position.text = "Question %d of %d" % [_question_index + 1, _questions.size()]
	_score.text = "%d correct" % _correct_count
	_progress.value = float(_question_index) / _questions.size()
	_prompt.text = question.prompt
	_feedback.visible = false
	_clear_choices()
	var is_ordering: bool = question.kind == QuizQuestion.Kind.ORDERING
	_choices.visible = not is_ordering
	_ordering.visible = is_ordering
	if is_ordering:
		_ordering.show_items(question.ordered_items)
		_advance.text = "Check order"
		_advance.disabled = false
		_key_hint.text = "Use the arrows to reorder, then press Enter to check."
	else:
		_ordering.clear()
		_build_choices(question)
		_advance.text = "Next question"
		_advance.disabled = true
		_key_hint.text = "Keys: 1 to %d pick an answer, Enter continues." % question.choices.size()
	_answers.scroll_vertical = 0


## Choice buttons differ per question, so they are created here rather than in the scene.
func _build_choices(question: QuizQuestion) -> void:
	_choice_order.assign(range(question.choices.size()))
	if question.kind == QuizQuestion.Kind.MULTIPLE_CHOICE:
		_choice_order.shuffle()
	for slot_index: int in _choice_order.size():
		var button: Button = Button.new()
		button.text = "%d.   %s" % [slot_index + 1, question.choices[_choice_order[slot_index]]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.focus_mode = Control.FOCUS_NONE
		if slot_index < CHOICE_KEYS.size():
			var key_event: InputEventKey = InputEventKey.new()
			key_event.keycode = CHOICE_KEYS[slot_index]
			var shortcut: Shortcut = Shortcut.new()
			shortcut.events = [key_event]
			button.shortcut = shortcut
			button.shortcut_in_tooltip = false
		button.pressed.connect(_answer_choice.bind(slot_index))
		_choices.add_child(button)
		_choice_buttons.append(button)


func _clear_choices() -> void:
	for button: Button in _choice_buttons:
		button.queue_free()
	_choice_buttons.clear()


func _answer_choice(slot_index: int) -> void:
	if _is_answered:
		return
	var question: QuizQuestion = _questions[_question_index]
	var is_correct: bool = _choice_order[slot_index] == question.correct_choice
	for button_index: int in _choice_buttons.size():
		var button: Button = _choice_buttons[button_index]
		button.disabled = true
		if _choice_order[button_index] == question.correct_choice:
			button.theme_type_variation = &"ChoiceCorrect"
		elif button_index == slot_index:
			button.theme_type_variation = &"ChoiceWrong"
	_finish_answer(is_correct)


func _finish_answer(is_correct: bool) -> void:
	var question: QuizQuestion = _questions[_question_index]
	_is_answered = true
	if is_correct:
		_correct_count += 1
	else:
		_missed.append(question)
	StudyProgress.record_answer(question.id, is_correct)
	_score.text = "%d correct" % _correct_count
	_feedback.theme_type_variation = &"FeedbackCorrect" if is_correct else &"FeedbackWrong"
	_verdict.theme_type_variation = &"VerdictCorrect" if is_correct else &"VerdictWrong"
	_verdict.text = "Correct!" if is_correct else "Not quite."
	_explanation.text = question.explanation
	_feedback.visible = true
	_advance.disabled = false
	var is_last: bool = _question_index == _questions.size() - 1
	_advance.text = "See results" if is_last else "Next question"
	_key_hint.text = "Press Enter to continue."
	# Wait a frame so the feedback panel has a size, then make sure it is on screen.
	await get_tree().process_frame
	_answers.ensure_control_visible(_feedback)


func _on_advance_pressed() -> void:
	var question: QuizQuestion = _questions[_question_index]
	if not _is_answered:
		if question.kind == QuizQuestion.Kind.ORDERING:
			_finish_answer(_ordering.check_against(question.ordered_items))
		return
	_question_index += 1
	if _question_index >= _questions.size():
		_finish_session()
	else:
		_show_question()


func _finish_session() -> void:
	var question_count: int = _questions.size()
	if not _score_module_id.is_empty() and question_count > 0:
		StudyProgress.record_quiz_score(_score_module_id, float(_correct_count) / question_count)
	var best_score: float = -1.0
	if not _score_module_id.is_empty():
		best_score = StudyProgress.best_quiz_score(_score_module_id)
	_session.visible = false
	_results.visible = true
	_results.show_results(_correct_count, question_count, _missed, best_score)
	session_finished.emit(_correct_count, question_count)
