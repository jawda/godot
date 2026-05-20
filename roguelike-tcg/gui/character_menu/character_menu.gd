class_name CharacterMenu
extends Control

enum _PendingAction { NONE, EXIT_TO_MENU, QUIT }

# ── Signals ────────────────────────────────────────────────────────────────────

signal closed
signal exit_to_main_menu_requested
signal quit_requested
signal level_up_requested

# ── Node references ────────────────────────────────────────────────────────────

@onready var _stats_button: Button    = $MenuPanel/VBox/TabBar/StatsButton
@onready var _gear_button: Button     = $MenuPanel/VBox/TabBar/GearButton
@onready var _settings_button: Button = $MenuPanel/VBox/TabBar/SettingsButton
@onready var _close_button: Button    = $MenuPanel/VBox/TabBar/CloseButton
@onready var _content_stack: Control  = $MenuPanel/VBox/ContentStack
@onready var _stats_tab: Control      = $MenuPanel/VBox/ContentStack/Stats
@onready var _gear_tab: Control       = $MenuPanel/VBox/ContentStack/Gear
@onready var _settings_tab: Control   = $MenuPanel/VBox/ContentStack/Settings

@onready var _save_prompt: Control          = $SavePrompt
@onready var _prompt_message: Label         = $SavePrompt/Dialog/Contents/Message
@onready var _save_leave_button: Button     = $SavePrompt/Dialog/Contents/Buttons/SaveAndLeave
@onready var _leave_no_save_button: Button  = $SavePrompt/Dialog/Contents/Buttons/LeaveWithoutSaving
@onready var _prompt_cancel_button: Button  = $SavePrompt/Dialog/Contents/Buttons/Cancel

# ── State ──────────────────────────────────────────────────────────────────────

var _pending_action: _PendingAction = _PendingAction.NONE

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_stats_button.toggled.connect(_on_stats_button_toggled)
	_gear_button.toggled.connect(_on_gear_button_toggled)
	_settings_button.toggled.connect(_on_settings_button_toggled)
	_close_button.pressed.connect(close)
	(_settings_tab as SettingsTab).exit_to_menu_requested.connect(_on_exit_to_menu_requested)
	(_settings_tab as SettingsTab).quit_requested.connect(_on_quit_requested)
	(_stats_tab as StatsTab).level_up_pressed.connect(_on_level_up_pressed)
	_save_leave_button.pressed.connect(_on_save_and_proceed)
	_leave_no_save_button.pressed.connect(_on_proceed_without_saving)
	_prompt_cancel_button.pressed.connect(_on_prompt_cancelled)
	_show_tab(_stats_tab)
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("Pause"):
		if _save_prompt.visible:
			_on_prompt_cancelled()
		else:
			close()
		get_viewport().set_input_as_handled()

# ── Public API ─────────────────────────────────────────────────────────────────

## Opens the menu populated from CharacterSaveData (used outside of an active run).
func open(player_data: PlayerData, character_save: CharacterSaveData) -> void:
	(_stats_tab as StatsTab).populate(player_data, character_save.active_run)
	(_gear_tab as GearTab).populate(character_save)
	_reset_tabs()
	show()

## Opens the menu populated from the active run's live state (used during a run).
func open_for_run(player_data: PlayerData, run_save: RunSaveData) -> void:
	(_stats_tab as StatsTab).populate(player_data, run_save)
	(_gear_tab as GearTab).populate_from_run(run_save)
	_reset_tabs()
	show()

func close() -> void:
	hide()
	closed.emit()

# ── Internal ───────────────────────────────────────────────────────────────────

func _reset_tabs() -> void:
	_show_tab(_stats_tab)
	_stats_button.button_pressed = true

func _show_tab(tab_to_show: Control) -> void:
	for tab_child: Node in _content_stack.get_children():
		tab_child.visible = (tab_child == tab_to_show)

func _on_stats_button_toggled(is_pressed: bool) -> void:
	if is_pressed:
		_show_tab(_stats_tab)

func _on_gear_button_toggled(is_pressed: bool) -> void:
	if is_pressed:
		_show_tab(_gear_tab)

func _on_settings_button_toggled(is_pressed: bool) -> void:
	if is_pressed:
		_show_tab(_settings_tab)

func _on_exit_to_menu_requested() -> void:
	_pending_action = _PendingAction.EXIT_TO_MENU
	_prompt_message.text = "Save your progress before returning to the main menu?"
	_save_leave_button.text = "Save & Exit"
	_leave_no_save_button.text = "Exit Without Saving"
	_save_prompt.show()

func _on_quit_requested() -> void:
	_pending_action = _PendingAction.QUIT
	_prompt_message.text = "Save your progress before quitting the game?"
	_save_leave_button.text = "Save & Quit"
	_leave_no_save_button.text = "Quit Without Saving"
	_save_prompt.show()

func _on_save_and_proceed() -> void:
	SaveManager.save()
	_execute_pending_action()

func _on_proceed_without_saving() -> void:
	_execute_pending_action()

func _on_prompt_cancelled() -> void:
	_pending_action = _PendingAction.NONE
	_save_prompt.hide()

func _on_level_up_pressed() -> void:
	hide()
	level_up_requested.emit()

func _execute_pending_action() -> void:
	_save_prompt.hide()
	var action: _PendingAction = _pending_action
	_pending_action = _PendingAction.NONE
	match action:
		_PendingAction.EXIT_TO_MENU:
			exit_to_main_menu_requested.emit()
		_PendingAction.QUIT:
			get_tree().quit()
