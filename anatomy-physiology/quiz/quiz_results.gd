class_name QuizResults
extends VBoxContainer
## End-of-quiz summary: score, best score, and the missed questions with their explanations.

signal retry_requested
signal retry_missed_requested

# ── Node references ──
@onready var _score: Label = $Score
@onready var _best_score: Label = $BestScore
@onready var _retry_missed: Button = $Actions/RetryMissed
@onready var _retry: Button = $Actions/Retry
@onready var _missed_heading: Label = $MissedHeading
@onready var _missed: RichTextLabel = $Missed


func _ready() -> void:
	_retry.pressed.connect(retry_requested.emit)
	_retry_missed.pressed.connect(retry_missed_requested.emit)


## best_score is -1.0 for review sessions, which have no per-module best.
func show_results(correct_count: int, question_count: int, missed_questions: Array[QuizQuestion], best_score: float) -> void:
	var percent: int = roundi(100.0 * correct_count / maxi(question_count, 1))
	_score.text = "%d / %d   (%d%%)" % [correct_count, question_count, percent]
	_best_score.visible = best_score >= 0.0
	_best_score.text = "Best score for this module: %d%%" % roundi(best_score * 100.0)
	_retry_missed.visible = not missed_questions.is_empty()
	_missed_heading.visible = not missed_questions.is_empty()
	_missed.visible = not missed_questions.is_empty()
	var answer_color: String = get_theme_color(&"correct", &"StudyPalette").to_html(false)
	var entries: PackedStringArray = []
	for question: QuizQuestion in missed_questions:
		entries.append("[b]%s[/b]\n[color=#%s]Answer: %s[/color]\n%s" % [
			question.prompt, answer_color, _answer_text(question), question.explanation])
	_missed.text = "\n\n".join(entries)
	_missed.scroll_to_line(0)


func _answer_text(question: QuizQuestion) -> String:
	if question.kind == QuizQuestion.Kind.ORDERING:
		return " → ".join(question.ordered_items)
	return question.choices[question.correct_choice]
