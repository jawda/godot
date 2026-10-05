class_name ProfileCard
extends PanelContainer
## One row on the profile screen.

signal open_requested(profile: StudyProfile)
signal rename_requested(profile: StudyProfile)
signal export_requested(profile: StudyProfile)
signal delete_requested(profile: StudyProfile)

var _profile: StudyProfile = null

# ── Node references ──
@onready var _name: Label = $Layout/Details/Name
@onready var _summary: Label = $Layout/Details/Summary
@onready var _rename: Button = $Layout/Rename
@onready var _export: Button = $Layout/Export
@onready var _delete: Button = $Layout/Delete
@onready var _open: Button = $Layout/Open


func _ready() -> void:
	_open.pressed.connect(func() -> void: open_requested.emit(_profile))
	_rename.pressed.connect(func() -> void: rename_requested.emit(_profile))
	_export.pressed.connect(func() -> void: export_requested.emit(_profile))
	_delete.pressed.connect(func() -> void: delete_requested.emit(_profile))


func show_profile(profile: StudyProfile, total_questions: int, is_last_used: bool) -> void:
	_profile = profile
	_name.text = profile.display_name
	var summary: Dictionary = StudyProgress.profile_summary(profile.id)
	_summary.text = "Last studied %s  ·  %d of %d questions mastered  ·  %d sections read" % [
		_describe_day(profile.last_used_unix), summary["mastered"], total_questions, summary["read"]]
	if is_last_used:
		_open.grab_focus.call_deferred()


func _describe_day(unix_seconds: float) -> String:
	var unix_time: int = int(unix_seconds)
	var today: String = Time.get_date_string_from_system()
	var day: String = Time.get_date_string_from_unix_time(unix_time + _utc_offset_seconds())
	if day == today:
		return "today"
	var date: Dictionary = Time.get_date_dict_from_unix_time(unix_time + _utc_offset_seconds())
	const MONTHS: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%s %d" % [MONTHS[int(date["month"]) - 1], int(date["day"])]


func _utc_offset_seconds() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60
