class_name ModuleMenu
extends MarginContainer
## Home screen: one tile per module plus the cross-module review entry points.

signal module_chosen(module: StudyModule)
signal mixed_review_requested
signal missed_review_requested
signal terminology_requested
signal continue_requested(module: StudyModule, tab: int)
signal switch_profile_requested

const MODULE_TILE_SCENE: PackedScene = preload("res://menu/module_tile.tscn")
const MINIMUM_TILE_WIDTH: float = 340.0

var _tiles: Array[ModuleTile] = []

# ── Node references ──
@onready var _studying_as: Label = $Layout/Header/Profile/StudyingAs
@onready var _switch_profile: Button = $Layout/Header/Profile/SwitchProfile
@onready var _continue: Button = $Layout/Actions/Continue
@onready var _overall: Label = $Layout/Actions/Overall
@onready var _mixed_review: Button = $Layout/Actions/MixedReview
@onready var _missed_questions: Button = $Layout/Actions/MissedQuestions
@onready var _medical_terms: Button = $Layout/Actions/MedicalTerms
@onready var _module_list: ScrollContainer = $Layout/ModuleList
@onready var _modules: GridContainer = $Layout/ModuleList/Modules
@onready var _load_note: Label = $Layout/Footer/LoadNote
@onready var _reset_progress: Button = $Layout/Footer/ResetProgress
@onready var _confirm_reset: ConfirmationDialog = $ConfirmReset


func _ready() -> void:
	_mixed_review.pressed.connect(mixed_review_requested.emit)
	_switch_profile.pressed.connect(switch_profile_requested.emit)
	_continue.pressed.connect(_on_continue_pressed)
	_missed_questions.pressed.connect(missed_review_requested.emit)
	_medical_terms.pressed.connect(terminology_requested.emit)
	_reset_progress.pressed.connect(_confirm_reset.popup_centered)
	_confirm_reset.confirmed.connect(StudyProgress.reset_all)
	StudyProgress.progress_changed.connect(refresh)
	_module_list.resized.connect(_fit_columns)
	_build_tiles()
	refresh()


func refresh() -> void:
	var profile: StudyProfile = StudyProgress.active_profile()
	_studying_as.text = "Studying as %s" % (profile.display_name if profile != null else "nobody")
	var last_module: StudyModule = _last_module()
	_continue.visible = last_module != null
	if last_module != null:
		_continue.text = "Continue: Module %d" % last_module.order
		_continue.tooltip_text = "Pick up where you left off in %s." % last_module.title
	_update_saved_note()
	for tile: ModuleTile in _tiles:
		tile.refresh_progress()
	var missed_count: int = StudyProgress.missed_question_ids().size()
	_missed_questions.text = "Missed questions (%d)" % missed_count
	_missed_questions.disabled = missed_count == 0
	_mixed_review.disabled = ContentLibrary.total_question_count() == 0
	_medical_terms.disabled = ContentLibrary.terms.is_empty()
	_overall.text = "%d of %d questions mastered across %d modules" % [
		StudyProgress.mastered_question_count(), ContentLibrary.total_question_count(),
		ContentLibrary.modules.size()]


func _on_continue_pressed() -> void:
	var last_module: StudyModule = _last_module()
	if last_module != null:
		continue_requested.emit(last_module, StudyProgress.last_tab())


func _last_module() -> StudyModule:
	for module: StudyModule in ContentLibrary.modules:
		if module.id == StudyProgress.last_module_id():
			return module
	return null


func _update_saved_note() -> void:
	if ContentLibrary.modules.is_empty():
		return
	var saved_unix: int = StudyProgress.last_saved_unix()
	if saved_unix == 0:
		_load_note.text = "Progress saves automatically after every answer, card, and page."
		return
	var local_time: Dictionary = Time.get_time_dict_from_unix_time(saved_unix + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	var hour: int = int(local_time["hour"])
	_load_note.text = "Saved automatically  ·  last saved %d:%02d %s" % [
		(hour + 11) % 12 + 1, int(local_time["minute"]), "AM" if hour < 12 else "PM"]


func _build_tiles() -> void:
	if ContentLibrary.modules.is_empty():
		_load_note.text = "No modules found in res://content/modules."
	for module: StudyModule in ContentLibrary.modules:
		var tile: ModuleTile = MODULE_TILE_SCENE.instantiate()
		_modules.add_child(tile)
		tile.show_module(module)
		tile.chosen.connect(module_chosen.emit)
		_tiles.append(tile)


## GridContainer has a fixed column count, so recompute it as the window resizes.
func _fit_columns() -> void:
	var available_width: float = _module_list.size.x
	_modules.columns = maxi(1, floori(available_width / MINIMUM_TILE_WIDTH))
