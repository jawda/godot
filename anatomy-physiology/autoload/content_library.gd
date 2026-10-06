extends Node
## AutoLoad: loads every module JSON file once at startup and serves them to the screens.
## (AutoLoad scripts cannot declare class_name; reach it through the global name ContentLibrary.)

const MODULES_DIRECTORY: String = "res://content/modules"
const TERMINOLOGY_DIRECTORY: String = "res://content/terminology"
## Generated terminology quiz questions use ids that start with this, so progress can
## tell them apart from module questions.
const TERMINOLOGY_QUESTION_PREFIX: String = "term_"
const TERMINOLOGY_MODULE_ID: String = "terminology"
const DISTRACTOR_COUNT: int = 3

var modules: Array[StudyModule] = []
## Every terminology entry, sorted by kind and then alphabetically.
var terms: Array[TermEntry] = []
var _questions_by_id: Dictionary[String, QuizQuestion] = {}
var _terms_by_id: Dictionary[String, TermEntry] = {}
var _term_questions_by_id: Dictionary[String, QuizQuestion] = {}
## Word part id -> the whole words built from it, for "used in" lists.
var _words_by_part_id: Dictionary[String, Array] = {}


func _ready() -> void:
	_load_modules()
	_load_terminology()


func get_question(question_id: String) -> QuizQuestion:
	if _questions_by_id.has(question_id):
		return _questions_by_id[question_id]
	return _term_questions_by_id.get(question_id, null)


func is_terminology_question(question_id: String) -> bool:
	return question_id.begins_with(TERMINOLOGY_QUESTION_PREFIX)


func get_term(term_id: String) -> TermEntry:
	return _terms_by_id.get(term_id, null)


## The whole words in the guide that are built from this word part, alphabetically.
func words_using_part(part_id: String) -> Array[TermEntry]:
	var words: Array[TermEntry] = []
	words.assign(_words_by_part_id.get(part_id, []))
	return words


## "oste/o (bone) + -blast (immature or forming cell)" for a word; empty for anything else.
func term_breakdown(entry: TermEntry) -> String:
	var pieces: PackedStringArray = []
	for part_id: String in entry.part_ids:
		var part: TermEntry = get_term(part_id)
		if part != null:
			pieces.append("%s (%s)" % [part.term, part.meaning])
	return " + ".join(pieces)


## One card per entry: the term on the front, the meaning (and a word's parts) on the back.
func terminology_flashcards(entries: Array[TermEntry]) -> Array[Flashcard]:
	var cards: Array[Flashcard] = []
	for entry: TermEntry in entries:
		var card: Flashcard = Flashcard.new()
		card.id = "%s%s_card" % [TERMINOLOGY_QUESTION_PREFIX, entry.id]
		card.term = entry.term
		card.definition = entry.meaning
		if entry.kind == TermEntry.Kind.WORD:
			card.definition += "\n\n" + term_breakdown(entry)
		elif not entry.examples.is_empty():
			card.definition += "\n\n" + entry.examples[0]
		cards.append(card)
	return cards


## The generated quiz questions for these entries: "what does it mean" for every entry,
## and "which term means" for everything except whole words.
func terminology_questions(entries: Array[TermEntry]) -> Array[QuizQuestion]:
	var questions: Array[QuizQuestion] = []
	for entry: TermEntry in entries:
		for question_id: String in [_meaning_question_id(entry), _term_question_id(entry)]:
			if _term_questions_by_id.has(question_id):
				questions.append(_term_questions_by_id[question_id])
	return questions


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
	var data: Variant = _read_json_object(path)
	return StudyModule.from_dictionary(data) if data is Dictionary else null


func _read_json_object(path: String) -> Variant:
	var text: String = FileAccess.get_file_as_string(path)
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		push_error("%s line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	if not json.data is Dictionary:
		push_error("%s: expected a JSON object at the top level" % path)
		return null
	return json.data


func _load_terminology() -> void:
	if not DirAccess.dir_exists_absolute(TERMINOLOGY_DIRECTORY):
		return
	for file_name: String in DirAccess.get_files_at(TERMINOLOGY_DIRECTORY):
		# Files starting with an underscore are scratch files for content writers.
		if not file_name.ends_with(".json") or file_name.begins_with("_"):
			continue
		var data: Variant = _read_json_object(TERMINOLOGY_DIRECTORY.path_join(file_name))
		if data == null:
			continue
		for entry_data: Variant in data.get("entries", []):
			var entry: TermEntry = TermEntry.from_dictionary(entry_data)
			if _terms_by_id.has(entry.id):
				push_warning("Duplicate terminology id %s in %s" % [entry.id, file_name])
				continue
			_terms_by_id[entry.id] = entry
			terms.append(entry)
	terms.sort_custom(func(first: TermEntry, second: TermEntry) -> bool:
		if first.kind != second.kind:
			return first.kind < second.kind
		return first.plain_term() < second.plain_term())
	for entry: TermEntry in terms:
		for part_id: String in entry.part_ids:
			if not _terms_by_id.has(part_id):
				push_warning("%s: unknown part id %s" % [entry.id, part_id])
			elif not _words_by_part_id.has(part_id):
				_words_by_part_id[part_id] = [entry]
			elif not _words_by_part_id[part_id].has(entry):
				_words_by_part_id[part_id].append(entry)
	_generate_terminology_questions()
	print("Loaded %d terminology entries, %d generated questions." % [terms.size(), _term_questions_by_id.size()])


func _generate_terminology_questions() -> void:
	var entries_by_pool: Dictionary[String, Array] = {}
	for entry: TermEntry in terms:
		var pool_key: String = _distractor_pool_key(entry)
		if not entries_by_pool.has(pool_key):
			entries_by_pool[pool_key] = []
		entries_by_pool[pool_key].append(entry)
	for entry: TermEntry in terms:
		var pool: Array = entries_by_pool[_distractor_pool_key(entry)]
		# Small body groups (positions, cavities) borrow distractors from every body term.
		if pool.size() <= DISTRACTOR_COUNT * 2 and entry.kind == TermEntry.Kind.BODY:
			pool = terms.filter(func(other: TermEntry) -> bool: return other.kind == TermEntry.Kind.BODY)
		var distractors: Array[TermEntry] = _pick_distractors(entry, pool)
		if distractors.size() < DISTRACTOR_COUNT:
			continue
		_add_term_question(entry, _meaning_question_id(entry),
			"What does \"%s\" mean?" % entry.term, entry.meaning,
			distractors.map(func(other: TermEntry) -> String: return other.meaning))
		if entry.kind != TermEntry.Kind.WORD:
			var noun: String = "word part" if entry.is_word_part() else "term"
			if entry.kind == TermEntry.Kind.ABBREVIATION:
				noun = "abbreviation"
			_add_term_question(entry, _term_question_id(entry),
				"Which %s means \"%s\"?" % [noun, entry.meaning], entry.term,
				distractors.map(func(other: TermEntry) -> String: return other.term))


func _add_term_question(entry: TermEntry, question_id: String, prompt: String,
		correct_answer: String, wrong_answers: Array) -> void:
	var question: QuizQuestion = QuizQuestion.new()
	question.id = question_id
	question.module_id = TERMINOLOGY_MODULE_ID
	question.kind = QuizQuestion.Kind.MULTIPLE_CHOICE
	question.prompt = prompt
	question.choices.append(correct_answer)
	question.choices.append_array(wrong_answers)
	question.correct_choice = 0
	question.explanation = "[b]%s[/b] means %s." % [entry.term, entry.meaning]
	if entry.kind == TermEntry.Kind.WORD:
		question.explanation += "\n" + term_breakdown(entry)
	elif not entry.examples.is_empty():
		question.explanation += "\nExample: " + entry.examples[0]
	_term_questions_by_id[question_id] = question


## Wrong answers come from the same kind of entry, never share a sense with the right
## answer, and are picked with a seed from the entry id so a question keeps the same
## choices from run to run (the Missed questions list depends on that).
func _pick_distractors(entry: TermEntry, pool: Array) -> Array[TermEntry]:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = hash(entry.id)
	var candidates: Array = pool.filter(func(other: TermEntry) -> bool:
		return other != entry and other.term.to_lower() != entry.term.to_lower() \
			and not _meanings_overlap(entry.meaning, other.meaning))
	var picked: Array[TermEntry] = []
	var used_senses: PackedStringArray = []
	while not candidates.is_empty() and picked.size() < DISTRACTOR_COUNT:
		var candidate: TermEntry = candidates.pop_at(random.randi_range(0, candidates.size() - 1))
		var overlaps_picked: bool = false
		for sense: String in _senses(candidate.meaning):
			if used_senses.has(sense):
				overlaps_picked = true
		if overlaps_picked:
			continue
		used_senses.append_array(_senses(candidate.meaning))
		picked.append(candidate)
	return picked


func _distractor_pool_key(entry: TermEntry) -> String:
	return "%d/%s" % [entry.kind, entry.group]


func _meanings_overlap(first_meaning: String, second_meaning: String) -> bool:
	var first_senses: PackedStringArray = _senses(first_meaning)
	for sense: String in _senses(second_meaning):
		if first_senses.has(sense):
			return true
	return false


## "below, under; deficient" -> ["below", "under", "deficient"]
func _senses(meaning: String) -> PackedStringArray:
	var senses: PackedStringArray = []
	for sense: String in meaning.to_lower().replace(";", ",").split(","):
		var trimmed: String = sense.strip_edges().trim_prefix("the ").trim_prefix("a ")
		if not trimmed.is_empty():
			senses.append(trimmed)
	return senses


func _meaning_question_id(entry: TermEntry) -> String:
	return "%s%s_meaning" % [TERMINOLOGY_QUESTION_PREFIX, entry.id]


func _term_question_id(entry: TermEntry) -> String:
	return "%s%s_term" % [TERMINOLOGY_QUESTION_PREFIX, entry.id]
