class_name ProfileSelect
extends MarginContainer
## Launch screen: pick, create, rename, delete, export, or import a study profile.

signal profile_chosen

const PROFILE_CARD_SCENE: PackedScene = preload("res://profiles/profile_card.tscn")

var _pending_profile: StudyProfile = null

# ── Node references ──
@onready var _profile_list: VBoxContainer = $Scroll/Center/Column/Profiles
@onready var _no_profiles: Label = $Scroll/Center/Column/NoProfiles
@onready var _name_input: LineEdit = $Scroll/Center/Column/NewProfile/NameInput
@onready var _create: Button = $Scroll/Center/Column/NewProfile/Create
@onready var _import: Button = $Scroll/Center/Column/NewProfile/Import
@onready var _message: Label = $Scroll/Center/Column/Message
@onready var _confirm_delete: ConfirmationDialog = $ConfirmDelete
@onready var _rename_dialog: ConfirmationDialog = $RenameDialog
@onready var _new_name: LineEdit = $RenameDialog/NewName
@onready var _export_dialog: FileDialog = $ExportDialog
@onready var _import_dialog: FileDialog = $ImportDialog


func _ready() -> void:
	_create.pressed.connect(_create_profile)
	_name_input.text_submitted.connect(func(_text: String) -> void: _create_profile())
	_import.pressed.connect(_import_dialog.popup_centered)
	_import_dialog.file_selected.connect(_import_profile)
	_export_dialog.file_selected.connect(_export_profile)
	_confirm_delete.confirmed.connect(_delete_pending)
	_rename_dialog.confirmed.connect(_rename_pending)
	_rename_dialog.register_text_enter(_new_name)
	refresh()


## One card per profile, so the cards are created here.
func refresh() -> void:
	for child: Node in _profile_list.get_children():
		child.queue_free()
	var all_profiles: Array[StudyProfile] = StudyProgress.profiles()
	_no_profiles.visible = all_profiles.is_empty()
	for profile: StudyProfile in all_profiles:
		var card: ProfileCard = PROFILE_CARD_SCENE.instantiate()
		_profile_list.add_child(card)
		card.show_profile(profile, ContentLibrary.total_question_count(), profile.id == StudyProgress.last_profile_id())
		card.open_requested.connect(_open_profile)
		card.rename_requested.connect(_ask_rename)
		card.export_requested.connect(_ask_export)
		card.delete_requested.connect(_ask_delete)
	if all_profiles.is_empty():
		_name_input.grab_focus.call_deferred()


func _create_profile() -> void:
	var display_name: String = _name_input.text.strip_edges()
	if display_name.is_empty():
		_show_message("Type a name first.")
		_name_input.grab_focus()
		return
	var profile: StudyProfile = StudyProgress.create_profile(display_name)
	_name_input.clear()
	_open_profile(profile)


func _open_profile(profile: StudyProfile) -> void:
	if StudyProgress.select_profile(profile.id):
		_show_message("")
		profile_chosen.emit()


func _ask_rename(profile: StudyProfile) -> void:
	_pending_profile = profile
	_new_name.text = profile.display_name
	_rename_dialog.popup_centered()
	_new_name.grab_focus()
	_new_name.select_all()


func _rename_pending() -> void:
	if _pending_profile != null:
		StudyProgress.rename_profile(_pending_profile.id, _new_name.text)
	refresh()


func _ask_delete(profile: StudyProfile) -> void:
	_pending_profile = profile
	_confirm_delete.dialog_text = "Delete \"%s\"? This permanently deletes the profile and all of its progress." % profile.display_name
	_confirm_delete.popup_centered()


func _delete_pending() -> void:
	if _pending_profile != null:
		StudyProgress.delete_profile(_pending_profile.id)
		_show_message("Deleted \"%s\"." % _pending_profile.display_name)
	refresh()


func _ask_export(profile: StudyProfile) -> void:
	_pending_profile = profile
	_export_dialog.current_file = "%s study progress.json" % profile.display_name.validate_filename()
	_export_dialog.popup_centered()


func _export_profile(path: String) -> void:
	if _pending_profile == null:
		return
	var error: Error = StudyProgress.export_profile(_pending_profile.id, path)
	if error == OK:
		_show_message("Exported \"%s\" to %s" % [_pending_profile.display_name, path])
	else:
		_show_message("Export failed: %s" % error_string(error))


func _import_profile(path: String) -> void:
	var profile: StudyProfile = StudyProgress.import_profile(path)
	if profile == null:
		_show_message("That file isn't a study guide profile.")
		return
	_show_message("Imported \"%s\"." % profile.display_name)
	refresh()


func _show_message(text: String) -> void:
	_message.text = text
