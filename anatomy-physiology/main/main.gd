class_name StudyGuide
extends Control
## Root scene. Owns the screens and switches between them; screens only emit signals.

# ── Node references ──
@onready var _profile_select: ProfileSelect = $ProfileSelect
@onready var _module_menu: ModuleMenu = $ModuleMenu
@onready var _module_study: ModuleStudy = $ModuleStudy
@onready var _review_session: ReviewSession = $ReviewSession


func _ready() -> void:
	_profile_select.profile_chosen.connect(_show_menu)
	_module_menu.module_chosen.connect(_on_module_chosen)
	_module_menu.continue_requested.connect(_on_continue_requested)
	_module_menu.mixed_review_requested.connect(_on_mixed_review_requested)
	_module_menu.missed_review_requested.connect(_on_missed_review_requested)
	_module_menu.switch_profile_requested.connect(_show_profiles)
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


func _show_screen(screen: Control) -> void:
	for candidate: Control in [_profile_select, _module_menu, _module_study, _review_session]:
		candidate.visible = candidate == screen
