class_name StartScreen
extends Control

const CHARACTER_SELECT_SCENE: String = "res://gui/character_select/character_select.tscn"
const FLOOR_LOOP_SCENE: String = "res://gui/floor_loop/floor_loop.tscn"

# Slot card colours (built dynamically in code).
const COLOR_EMPTY_BG: Color     = Color(0.07, 0.04, 0.12, 0.85)
const COLOR_EMPTY_BORDER: Color = Color(0.28, 0.14, 0.44, 0.50)
const COLOR_FULL_BG: Color      = Color(0.09, 0.05, 0.15, 0.92)
const COLOR_FULL_BORDER: Color  = Color(0.44, 0.22, 0.66, 0.75)
const COLOR_NAME_EMPTY: Color   = Color(0.50, 0.44, 0.66, 0.65)
const COLOR_NAME: Color         = Color(0.88, 0.82, 1.0, 1.0)
const COLOR_RUN_INFO: Color     = Color(0.62, 0.56, 0.80, 0.90)
const COLOR_CONTINUE: Color     = Color(0.95, 0.82, 0.42, 1.0)
const COLOR_NEW_GAME: Color     = Color(0.65, 0.58, 0.85, 1.0)
const COLOR_DELETE: Color       = Color(0.70, 0.34, 0.34, 1.0)

# ── Node references ───────────────────────────────────────────────────────────

@onready var _slot_list: VBoxContainer  = %SlotList
@onready var _settings_button: Button   = %Settings
@onready var _quit_button: Button       = %Quit
@onready var _settings_overlay: Control = $SettingsOverlay
@onready var _settings_tab: SettingsTab = $SettingsOverlay/Centered/Dialog/SettingsMenu

@onready var _name_prompt: Control         = $NamePrompt
@onready var _name_input: LineEdit         = $NamePrompt/Dialog/Contents/NameInput
@onready var _name_confirm_button: Button  = $NamePrompt/Dialog/Contents/Buttons/ConfirmButton
@onready var _name_cancel_button: Button   = $NamePrompt/Dialog/Contents/Buttons/CancelButton

@onready var _confirm_prompt: Control      = $ConfirmPrompt
@onready var _confirm_message: Label       = $ConfirmPrompt/Dialog/Contents/ConfirmMessage
@onready var _confirm_yes_button: Button   = $ConfirmPrompt/Dialog/Contents/Buttons/YesButton
@onready var _confirm_no_button: Button    = $ConfirmPrompt/Dialog/Contents/Buttons/NoButton

# ── State ─────────────────────────────────────────────────────────────────────

var _pending_slot_index: int = -1
var _pending_confirm_action: Callable = Callable()

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_settings_button.pressed.connect(func() -> void: _settings_overlay.show())
	_quit_button.pressed.connect(func() -> void: get_tree().quit())

	_name_input.text_submitted.connect(func(_text: String) -> void: _on_name_confirmed())
	_name_confirm_button.pressed.connect(_on_name_confirmed)
	_name_cancel_button.pressed.connect(func() -> void: _name_prompt.hide())

	_confirm_yes_button.pressed.connect(_on_confirm_yes)
	_confirm_no_button.pressed.connect(func() -> void: _confirm_prompt.hide())

	_settings_tab.exit_to_menu_requested.connect(func() -> void: _settings_overlay.hide())
	_settings_tab.quit_requested.connect(func() -> void: get_tree().quit())

	_build_slot_cards()
	_settings_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _name_prompt.visible:
		_name_prompt.hide()
		get_viewport().set_input_as_handled()
	elif _confirm_prompt.visible:
		_confirm_prompt.hide()
		get_viewport().set_input_as_handled()
	elif _settings_overlay.visible:
		_settings_overlay.hide()
		get_viewport().set_input_as_handled()

# ── Slot card building ────────────────────────────────────────────────────────

func _build_slot_cards() -> void:
	for child: Node in _slot_list.get_children():
		child.queue_free()
	for slot_index: int in range(SaveManager.SLOT_COUNT):
		_slot_list.add_child(_build_slot_card(slot_index))

func _build_slot_card(slot_index: int) -> PanelContainer:
	var slot_data: SaveData = SaveManager.get_slot(slot_index)
	var is_empty: bool = slot_data == null
	var active_char_save: CharacterSaveData = null if is_empty else _find_active_char_save(slot_data)
	var has_run: bool = active_char_save != null

	var card: PanelContainer = PanelContainer.new()
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.content_margin_left   = 18.0
	card_style.content_margin_top    = 14.0
	card_style.content_margin_right  = 18.0
	card_style.content_margin_bottom = 14.0
	card_style.bg_color = COLOR_EMPTY_BG if is_empty else COLOR_FULL_BG
	card_style.set_border_width_all(1)
	card_style.border_color = COLOR_EMPTY_BORDER if is_empty else COLOR_FULL_BORDER
	card_style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(480, 0)

	var contents: VBoxContainer = VBoxContainer.new()
	contents.add_theme_constant_override("separation", 8)
	card.add_child(contents)

	var name_label: Label = Label.new()
	name_label.add_theme_font_size_override("font_size", 17)
	if is_empty:
		name_label.text = "Empty Slot %d" % (slot_index + 1)
		name_label.add_theme_color_override("font_color", COLOR_NAME_EMPTY)
	else:
		name_label.text = slot_data.slot_name if not slot_data.slot_name.is_empty() \
				else "Slot %d" % (slot_index + 1)
		name_label.add_theme_color_override("font_color", COLOR_NAME)
	contents.add_child(name_label)

	if has_run:
		var run_info: Label = Label.new()
		run_info.add_theme_font_size_override("font_size", 12)
		run_info.add_theme_color_override("font_color", COLOR_RUN_INFO)
		run_info.text = _format_run_info(active_char_save)
		contents.add_child(run_info)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	contents.add_child(button_row)

	if has_run:
		var continue_btn: Button = Button.new()
		continue_btn.text = "Continue"
		continue_btn.flat = true
		continue_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		continue_btn.add_theme_font_size_override("font_size", 13)
		continue_btn.add_theme_color_override("font_color", COLOR_CONTINUE)
		continue_btn.pressed.connect(_on_continue_slot.bind(slot_index))
		button_row.add_child(continue_btn)

	var new_game_btn: Button = Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.flat = true
	new_game_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	new_game_btn.add_theme_font_size_override("font_size", 13)
	new_game_btn.add_theme_color_override("font_color", COLOR_NEW_GAME)
	new_game_btn.pressed.connect(_on_new_game_slot.bind(slot_index))
	button_row.add_child(new_game_btn)

	if not is_empty:
		var spacer: Control = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_row.add_child(spacer)

		var delete_btn: Button = Button.new()
		delete_btn.text = "Delete"
		delete_btn.flat = true
		delete_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		delete_btn.add_theme_font_size_override("font_size", 12)
		delete_btn.add_theme_color_override("font_color", COLOR_DELETE)
		delete_btn.pressed.connect(_on_delete_slot.bind(slot_index))
		button_row.add_child(delete_btn)

	return card

func _format_run_info(char_save: CharacterSaveData) -> String:
	var player_data: PlayerData = load(char_save.character_id) as PlayerData
	var class_label: String = player_data.character_class.capitalize() if player_data else "Unknown"
	return "%s  ·  Floor %d" % [class_label, char_save.active_run.current_floor]

func _find_active_char_save(slot_data: SaveData) -> CharacterSaveData:
	for char_save: CharacterSaveData in slot_data.character_saves:
		if char_save.active_run != null:
			return char_save
	return null

# ── Slot actions ──────────────────────────────────────────────────────────────

func _on_continue_slot(slot_index: int) -> void:
	var slot_data: SaveData = SaveManager.get_slot(slot_index)
	var char_save: CharacterSaveData = _find_active_char_save(slot_data)
	if char_save == null:
		return
	var player_data: PlayerData = load(char_save.character_id) as PlayerData
	if player_data == null:
		push_warning("StartScreen: could not load PlayerData at %s" % char_save.character_id)
		return
	SaveManager.set_active_slot(slot_index)
	RunState.resume_run(player_data, char_save)
	SceneTransition.transition_to(FLOOR_LOOP_SCENE)

func _on_new_game_slot(slot_index: int) -> void:
	var slot_data: SaveData = SaveManager.get_slot(slot_index)
	if slot_data == null:
		_pending_slot_index = slot_index
		_name_input.text = ""
		_name_prompt.show()
		_name_input.grab_focus()
	elif _find_active_char_save(slot_data) != null:
		_pending_slot_index = slot_index
		_confirm_message.text = "Start a new run? Your current run will be abandoned."
		_pending_confirm_action = func() -> void:
			_confirm_prompt.hide()
			SaveManager.set_active_slot(slot_index)
			SceneTransition.transition_to(CHARACTER_SELECT_SCENE)
		_confirm_prompt.show()
	else:
		SaveManager.set_active_slot(slot_index)
		SceneTransition.transition_to(CHARACTER_SELECT_SCENE)

func _on_delete_slot(slot_index: int) -> void:
	_pending_slot_index = slot_index
	_confirm_message.text = "Delete this save? This cannot be undone."
	_pending_confirm_action = func() -> void:
		SaveManager.delete_slot(slot_index)
		_confirm_prompt.hide()
		_build_slot_cards()
	_confirm_prompt.show()

# ── Prompt handlers ───────────────────────────────────────────────────────────

func _on_name_confirmed() -> void:
	var slot_name: String = _name_input.text.strip_edges()
	if slot_name.is_empty():
		return
	_name_prompt.hide()
	SaveManager.set_active_slot(_pending_slot_index)
	SaveManager.save_data.slot_name = slot_name
	SceneTransition.transition_to(CHARACTER_SELECT_SCENE)

func _on_confirm_yes() -> void:
	if _pending_confirm_action.is_valid():
		_pending_confirm_action.call()
		_pending_confirm_action = Callable()
