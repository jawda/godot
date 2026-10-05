class_name StudyModule
extends RefCounted
## One chapter of study material, loaded from a JSON file in content/modules.

var id: String = ""
var order: int = 0
var course: String = ""
var title: String = ""
var summary: String = ""
var objectives: Array[String] = []
var lesson_sections: Array[LessonSection] = []
var flashcards: Array[Flashcard] = []
var quiz_questions: Array[QuizQuestion] = []


static func from_dictionary(data: Dictionary) -> StudyModule:
	var module: StudyModule = StudyModule.new()
	module.id = str(data.get("id", ""))
	module.order = int(data.get("order", 0))
	module.course = str(data.get("course", ""))
	module.title = str(data.get("title", ""))
	module.summary = str(data.get("summary", ""))
	module.objectives.assign(data.get("objectives", []))
	for section_data: Dictionary in data.get("lesson", []):
		module.lesson_sections.append(LessonSection.from_dictionary(section_data))
	for card_data: Dictionary in data.get("flashcards", []):
		module.flashcards.append(Flashcard.from_dictionary(card_data))
	for question_data: Dictionary in data.get("quiz", []):
		module.quiz_questions.append(QuizQuestion.from_dictionary(question_data, module.id))
	return module
