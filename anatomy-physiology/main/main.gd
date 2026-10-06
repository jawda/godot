class_name StudyGuide
extends Control
## Root scene. Owns the screens and switches between them; screens only emit signals.

# ── Node references ──
@onready var _profile_select: ProfileSelect = $ProfileSelect
@onready var _module_menu: ModuleMenu = $ModuleMenu
@onready var _module_study: ModuleStudy = $ModuleStudy
@onready var _review_session: ReviewSession = $ReviewSession
@onready var _terminology: TerminologyScreen = $TerminologyScreen

## The screen Medical terms was opened from, so its back button returns there.
var _screen_before_terminology: Control = null


func _ready() -> void:
	_profile_select.profile_chosen.connect(_show_menu)
	_module_menu.module_chosen.connect(_on_module_chosen)
	_module_menu.continue_requested.connect(_on_continue_requested)
	_module_menu.mixed_review_requested.connect(_on_mixed_review_requested)
	_module_menu.missed_review_requested.connect(_on_missed_review_requested)
	_module_menu.switch_profile_requested.connect(_show_profiles)
	_module_menu.terminology_requested.connect(_show_terminology)
	_module_study.terminology_requested.connect(_show_terminology)
	_terminology.back_requested.connect(_on_terminology_back)
	_module_study.back_requested.connect(_show_menu)
	_review_session.back_requested.connect(_show_menu)
	_show_profiles()


func _show_profiles() -> void:
	_profile_select.refresh()
	_show_screen(_profile_select)


func _show_menu() -> void:
	_module_menu.refresh()
	_show_screen(_module_menu)


func _on_module_chosen(module: StudyModule) -> void:
	_module_study.show_module(module)
	_show_screen(_module_study)


func _on_continue_requested(module: StudyModule, tab: int) -> void:
	_module_study.show_module(module, tab)
	_show_screen(_module_study)


func _on_mixed_review_requested() -> void:
	_review_session.start_mixed_review()
	_show_screen(_review_session)


func _on_missed_review_requested() -> void:
	_review_session.start_missed_review()
	_show_screen(_review_session)


func _show_terminology(entry: TermEntry = null) -> void:
	_screen_before_terminology = _module_study if _module_study.visible else _module_menu
	var back_text: String = "← Back to the lesson" if _module_study.visible else "← All modules"
	_terminology.open(entry, back_text)
	_show_screen(_terminology)


func _on_terminology_back() -> void:
	if _screen_before_terminology == _module_study:
		_show_screen(_module_study)
	else:
		_show_menu()


func _show_screen(screen: Control) -> void:
	for candidate: Control in [_profile_select, _module_menu, _module_study, _review_session, _terminology]:
		candidate.visible = candidate == screen
