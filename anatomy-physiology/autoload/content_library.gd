extends Node
## AutoLoad: loads every module JSON file once at startup and serves them to the screens.
## (AutoLoad scripts cannot declare class_name; reach it through the global name ContentLibrary.)

const MODULES_DIRECTORY: String = "res://content/modules"

var modules: Array[StudyModule] = []
var _questions_by_id: Dictionary[String, QuizQuestion] = {}


func _ready() -> void:
	_load_modules()


func get_question(question_id: String) -> QuizQuestion:
	return _questions_by_id.get(question_id, null)


func all_questions() -> Array[QuizQuestion]:
	var questions: Array[QuizQuestion] = []
	questions.assign(_questions_by_id.values())
	return questions


func total_question_count() -> int:
	return _questions_by_id.size()


func _load_modules() -> void:
	for file_name: String in DirAccess.get_files_at(MODULES_DIRECTORY):
		if not file_name.ends_with(".json"):
			continue
		var module: StudyModule = _load_module_file(MODULES_DIRECTORY.path_join(file_name))
		if module == null:
			continue
		modules.append(module)
		for question: QuizQuestion in module.quiz_questions:
			if _questions_by_id.has(question.id):
				push_warning("Duplicate question id %s in %s" % [question.id, file_name])
			_questions_by_id[question.id] = question
	modules.sort_custom(func(first: StudyModule, second: StudyModule) -> bool: return first.order < second.order)
	if modules.is_empty():
		push_error("No study modules found in %s" % MODULES_DIRECTORY)
	else:
		print("Loaded %d study modules." % modules.size())


func _load_module_file(path: String) -> StudyModule:
	var text: String = FileAccess.get_file_as_string(path)
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		push_error("%s line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	if not json.data is Dictionary:
		push_error("%s: expected a JSON object at the top level" % path)
		return null
	return StudyModule.from_dictionary(json.data)
