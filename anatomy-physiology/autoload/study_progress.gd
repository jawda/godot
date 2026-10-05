extends Node
## AutoLoad: study profiles and each profile's progress (quiz results, known flashcards,
## sections read, where you left off). Every change is written to disk straight away.
##
## Files live under user://, which is
##   Windows: %APPDATA%\Godot\app_userdata\A&P Study Guide\profiles\
##   macOS:   ~/Library/Application Support/Godot/app_userdata/A&P Study Guide/profiles/

signal progress_changed
signal profiles_changed

const PROFILES_DIRECTORY: String = "user://profiles"
## The smoke test works in its own folder so it never touches real profiles.
const TEST_PROFILES_DIRECTORY: String = "user://smoke_test_profiles"
const TEST_SCENE: String = "res://tests/smoke_test.tscn"
const INDEX_FILE: String = "index.json"
## Single-file save from before profiles existed; migrated into a profile on first launch.
const LEGACY_SAVE_PATH: String = "user://study_progress.json"
const SAVE_FORMAT: int = 2

var _directory: String = PROFILES_DIRECTORY
var _profiles: Array[StudyProfile] = []
var _last_profile_id: String = ""
var _active_profile: StudyProfile = null
var _last_saved_unix: int = 0

## The most recent result per question id. A question absent from this map was never answered.
var _last_result_by_question: Dictionary[String, bool] = {}
var _known_flashcards: Dictionary[String, bool] = {}
var _best_score_by_module: Dictionary[String, float] = {}
## Keys from lesson_section_key().
var _read_sections: Dictionary[String, bool] = {}
## Module id -> (section index, page index) of the last lesson page shown.
var _lesson_positions: Dictionary[String, Vector2i] = {}
var _last_module_id: String = ""
var _last_tab: int = 0


func _ready() -> void:
	if OS.get_cmdline_args().has(TEST_SCENE):
		_directory = TEST_PROFILES_DIRECTORY
	DirAccess.make_dir_recursive_absolute(_directory)
	_load_index()
	_migrate_legacy_save()


# ── Profiles ──

func profiles() -> Array[StudyProfile]:
	var sorted_profiles: Array[StudyProfile] = _profiles.duplicate()
	sorted_profiles.sort_custom(func(first: StudyProfile, second: StudyProfile) -> bool:
		return first.last_used_unix > second.last_used_unix)
	return sorted_profiles


func active_profile() -> StudyProfile:
	return _active_profile


func last_profile_id() -> String:
	return _last_profile_id


func last_saved_unix() -> int:
	return _last_saved_unix


func create_profile(display_name: String) -> StudyProfile:
	var profile: StudyProfile = StudyProfile.new()
	profile.id = "%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 100000]
	profile.display_name = _unique_name(display_name.strip_edges())
	profile.created_unix = Time.get_unix_time_from_system()
	profile.last_used_unix = profile.created_unix
	_profiles.append(profile)
	_write_json(_profile_path(profile.id), _empty_progress_data(profile))
	_save_index()
	return profile


func rename_profile(profile_id: String, display_name: String) -> void:
	var profile: StudyProfile = _find_profile(profile_id)
	if profile == null or display_name.strip_edges().is_empty():
		return
	profile.display_name = display_name.strip_edges()
	_save_index()
	if profile == _active_profile:
		_save()


func delete_profile(profile_id: String) -> void:
	var profile: StudyProfile = _find_profile(profile_id)
	if profile == null:
		return
	if profile == _active_profile:
		_active_profile = null
		_clear_progress()
	_profiles.erase(profile)
	DirAccess.remove_absolute(_profile_path(profile_id))
	if _last_profile_id == profile_id:
		_last_profile_id = ""
	_save_index()


func select_profile(profile_id: String) -> bool:
	var profile: StudyProfile = _find_profile(profile_id)
	if profile == null:
		return false
	_clear_progress()
	_active_profile = profile
	_load_progress(_read_json(_profile_path(profile_id)))
	profile.last_used_unix = Time.get_unix_time_from_system()
	_last_profile_id = profile_id
	_save_index()
	progress_changed.emit()
	return true


## Writes a profile's progress to a file anywhere on disk, for moving between computers.
func export_profile(profile_id: String, absolute_path: String) -> Error:
	var profile: StudyProfile = _find_profile(profile_id)
	if profile == null:
		return ERR_DOES_NOT_EXIST
	var data: Variant = _read_json(_profile_path(profile_id))
	if not data is Dictionary:
		return ERR_FILE_CORRUPT
	var export_data: Dictionary = data
	export_data["name"] = profile.display_name
	return _write_json(absolute_path, export_data)


## Adds a new profile from an exported file. Returns null if the file isn't a profile.
func import_profile(absolute_path: String) -> StudyProfile:
	var data: Variant = _read_json(absolute_path)
	if not data is Dictionary or not (data as Dictionary).has("answers"):
		return null
	var import_data: Dictionary = data
	var profile: StudyProfile = create_profile(str(import_data.get("name", "Imported")))
	_write_json(_profile_path(profile.id), import_data)
	return profile


## Headline numbers for a profile card, read from disk so the profile needn't be active.
func profile_summary(profile_id: String) -> Dictionary:
	var data: Variant = _read_json(_profile_path(profile_id))
	var mastered_count: int = 0
	var read_count: int = 0
	if data is Dictionary:
		var answers: Dictionary = (data as Dictionary).get("answers", {})
		for was_correct: Variant in answers.values():
			if bool(was_correct):
				mastered_count += 1
		read_count = ((data as Dictionary).get("read_sections", []) as Array).size()
	return {"mastered": mastered_count, "read": read_count}


# ── Where you left off ──

func set_last_place(module_id: String, tab: int) -> void:
	_last_module_id = module_id
	_last_tab = tab
	_save()


func last_module_id() -> String:
	return _last_module_id


func last_tab() -> int:
	return _last_tab


func save_lesson_position(module_id: String, section_index: int, page_index: int) -> void:
	_lesson_positions[module_id] = Vector2i(section_index, page_index)
	_save()


## Returns (-1, -1) when the module's lesson has never been opened.
func lesson_position(module_id: String) -> Vector2i:
	return _lesson_positions.get(module_id, Vector2i(-1, -1))


# ── Quiz and flashcard progress ──

func record_answer(question_id: String, was_correct: bool) -> void:
	_last_result_by_question[question_id] = was_correct
	_save()


func was_answered(question_id: String) -> bool:
	return _last_result_by_question.has(question_id)


func is_missed(question_id: String) -> bool:
	return _last_result_by_question.get(question_id, true) == false


func missed_question_ids() -> Array[String]:
	var missed_ids: Array[String] = []
	for question_id: String in _last_result_by_question:
		if not _last_result_by_question[question_id]:
			missed_ids.append(question_id)
	return missed_ids


func set_flashcard_known(card_id: String, is_known: bool) -> void:
	if is_known:
		_known_flashcards[card_id] = true
	else:
		_known_flashcards.erase(card_id)
	_save()


func is_flashcard_known(card_id: String) -> bool:
	return _known_flashcards.has(card_id)


func lesson_section_key(module: StudyModule, heading: String) -> String:
	return "%s/%s" % [module.id, heading]


func mark_section_read(section_key: String) -> void:
	if _read_sections.has(section_key):
		return
	_read_sections[section_key] = true
	_save()


func is_section_read(section_key: String) -> bool:
	return _read_sections.has(section_key)


func read_section_count(module: StudyModule) -> int:
	var read_count: int = 0
	for section: LessonSection in module.lesson_sections:
		if is_section_read(lesson_section_key(module, section.heading)):
			read_count += 1
	return read_count


func record_quiz_score(module_id: String, score_fraction: float) -> void:
	_best_score_by_module[module_id] = maxf(best_quiz_score(module_id), score_fraction)
	_save()


## Returns -1.0 when the module's quiz has never been finished.
func best_quiz_score(module_id: String) -> float:
	return _best_score_by_module.get(module_id, -1.0)


## Fraction of a module's questions whose most recent answer was correct.
func question_mastery(module: StudyModule) -> float:
	if module.quiz_questions.is_empty():
		return 0.0
	var mastered_count: int = 0
	for question: QuizQuestion in module.quiz_questions:
		if _last_result_by_question.get(question.id, false):
			mastered_count += 1
	return float(mastered_count) / module.quiz_questions.size()


func known_flashcard_count(module: StudyModule) -> int:
	var known_count: int = 0
	for card: Flashcard in module.flashcards:
		if is_flashcard_known(card.id):
			known_count += 1
	return known_count


func has_started(module: StudyModule) -> bool:
	for question: QuizQuestion in module.quiz_questions:
		if was_answered(question.id):
			return true
	return known_flashcard_count(module) > 0 or read_section_count(module) > 0


func mastered_question_count() -> int:
	var mastered_count: int = 0
	for was_correct: bool in _last_result_by_question.values():
		if was_correct:
			mastered_count += 1
	return mastered_count


## Clears the active profile's progress but keeps the profile.
func reset_all() -> void:
	_clear_progress()
	_save()


# ── Persistence ──

func _clear_progress() -> void:
	_last_result_by_question.clear()
	_known_flashcards.clear()
	_best_score_by_module.clear()
	_read_sections.clear()
	_lesson_positions.clear()
	_last_module_id = ""
	_last_tab = 0


func _save() -> void:
	if _active_profile == null:
		return
	var positions: Dictionary = {}
	for module_id: String in _lesson_positions:
		var position: Vector2i = _lesson_positions[module_id]
		positions[module_id] = [position.x, position.y]
	var save_data: Dictionary = {
		"format": SAVE_FORMAT,
		"name": _active_profile.display_name,
		"answers": _last_result_by_question,
		"known_flashcards": _known_flashcards.keys(),
		"best_scores": _best_score_by_module,
		"read_sections": _read_sections.keys(),
		"lesson_positions": positions,
		"last_module": _last_module_id,
		"last_tab": _last_tab,
	}
	if _write_json(_profile_path(_active_profile.id), save_data) == OK:
		_last_saved_unix = int(Time.get_unix_time_from_system())
	progress_changed.emit()


func _load_progress(parsed: Variant) -> void:
	if not parsed is Dictionary:
		return
	var save_data: Dictionary = parsed
	var answers: Dictionary = save_data.get("answers", {})
	for question_id: String in answers:
		_last_result_by_question[question_id] = bool(answers[question_id])
	for card_id: String in save_data.get("known_flashcards", []):
		_known_flashcards[card_id] = true
	for section_key: String in save_data.get("read_sections", []):
		_read_sections[section_key] = true
	var best_scores: Dictionary = save_data.get("best_scores", {})
	for module_id: String in best_scores:
		_best_score_by_module[module_id] = float(best_scores[module_id])
	var positions: Dictionary = save_data.get("lesson_positions", {})
	for module_id: String in positions:
		var position: Array = positions[module_id]
		if position.size() == 2:
			_lesson_positions[module_id] = Vector2i(int(position[0]), int(position[1]))
	_last_module_id = str(save_data.get("last_module", ""))
	_last_tab = int(save_data.get("last_tab", 0))


func _empty_progress_data(profile: StudyProfile) -> Dictionary:
	return {"format": SAVE_FORMAT, "name": profile.display_name, "answers": {}}


func _load_index() -> void:
	var parsed: Variant = _read_json(_directory.path_join(INDEX_FILE))
	if not parsed is Dictionary:
		return
	var index: Dictionary = parsed
	_last_profile_id = str(index.get("last_profile", ""))
	for profile_data: Dictionary in index.get("profiles", []):
		var profile: StudyProfile = StudyProfile.from_dictionary(profile_data)
		if FileAccess.file_exists(_profile_path(profile.id)):
			_profiles.append(profile)


func _save_index() -> void:
	var profile_entries: Array[Dictionary] = []
	for profile: StudyProfile in _profiles:
		profile_entries.append(profile.to_dictionary())
	_write_json(_directory.path_join(INDEX_FILE), {"last_profile": _last_profile_id, "profiles": profile_entries})
	profiles_changed.emit()


func _migrate_legacy_save() -> void:
	if _directory != PROFILES_DIRECTORY or not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return
	var legacy_data: Variant = _read_json(LEGACY_SAVE_PATH)
	if legacy_data is Dictionary:
		var profile: StudyProfile = create_profile("My progress")
		_write_json(_profile_path(profile.id), legacy_data)
	DirAccess.rename_absolute(LEGACY_SAVE_PATH, LEGACY_SAVE_PATH + ".migrated")


func _find_profile(profile_id: String) -> StudyProfile:
	for profile: StudyProfile in _profiles:
		if profile.id == profile_id:
			return profile
	return null


func _unique_name(display_name: String) -> String:
	var base_name: String = display_name if not display_name.is_empty() else "Student"
	var candidate: String = base_name
	var suffix: int = 2
	while _profiles.any(func(profile: StudyProfile) -> bool: return profile.display_name == candidate):
		candidate = "%s (%d)" % [base_name, suffix]
		suffix += 1
	return candidate


func _profile_path(profile_id: String) -> String:
	return _directory.path_join("%s.json" % profile_id)


## Writes to a temporary file first and then swaps it in, so a crash or power cut
## mid-write can't leave a half-written save behind.
func _write_json(path: String, data: Dictionary) -> Error:
	var temporary_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(temporary_path, path)


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		# A crash between remove and rename leaves only the temporary file; recover it.
		if FileAccess.file_exists(path + ".tmp"):
			DirAccess.rename_absolute(path + ".tmp", path)
		else:
			return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))
