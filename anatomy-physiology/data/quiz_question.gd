class_name QuizQuestion
extends RefCounted

enum Kind { MULTIPLE_CHOICE, TRUE_FALSE, ORDERING }

const KIND_BY_NAME: Dictionary[String, Kind] = {
	"multiple_choice": Kind.MULTIPLE_CHOICE,
	"true_false": Kind.TRUE_FALSE,
	"ordering": Kind.ORDERING,
}

var id: String = ""
var module_id: String = ""
var kind: Kind = Kind.MULTIPLE_CHOICE
var prompt: String = ""
## Answer options for multiple choice and true/false. True/false is stored as ["True", "False"].
var choices: Array[String] = []
var correct_choice: int = 0
## Ordering questions: the items in their correct order.
var ordered_items: Array[String] = []
var explanation: String = ""


static func from_dictionary(data: Dictionary, owning_module_id: String) -> QuizQuestion:
	var question: QuizQuestion = QuizQuestion.new()
	question.id = str(data.get("id", ""))
	question.module_id = owning_module_id
	question.kind = KIND_BY_NAME.get(str(data.get("type", "multiple_choice")), Kind.MULTIPLE_CHOICE)
	question.prompt = str(data.get("prompt", ""))
	question.explanation = str(data.get("explanation", ""))
	match question.kind:
		Kind.MULTIPLE_CHOICE:
			question.choices.assign(data.get("choices", []))
			question.correct_choice = int(data.get("answer", 0))
		Kind.TRUE_FALSE:
			question.choices.assign(["True", "False"])
			question.correct_choice = 0 if bool(data.get("answer", true)) else 1
		Kind.ORDERING:
			question.ordered_items.assign(data.get("items", []))
	return question
