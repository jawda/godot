class_name CharacterMenu
extends Control

# Note: Input handling (e.g. Escape key to close) should be added when input mapping is set up.

# ── Signals ────────────────────────────────────────────────────────────────────

## Emitted when the player dismisses the menu and returns to the game.
signal closed
signal exit_to_main_menu_requested
signal quit_requested

# ── Node references ────────────────────────────────────────────────────────────

@onready var _stats_button: Button = $MenuPanel/VBox/TabBar/StatsButton
@onready var _gear_button: Button = $MenuPanel/VBox/TabBar/GearButton
@onready var _settings_button: Button = $MenuPanel/VBox/TabBar/SettingsButton
@onready var _close_button: Button = $MenuPanel/VBox/TabBar/CloseButton
@onready var _content_stack: Control = $MenuPanel/VBox/ContentStack
@onready var _stats_tab: Control = $MenuPanel/VBox/ContentStack/Stats
@onready var _gear_tab: Control = $MenuPanel/VBox/ContentStack/Gear
@onready var _settings_tab: Control = $MenuPanel/VBox/ContentStack/Settings

# ── Internal state ─────────────────────────────────────────────────────────────

var _player_data: PlayerData
var _character_save: CharacterSaveData

func _ready() -> void:
	_stats_button.toggled.connect(_on_stats_button_toggled)
	_gear_button.toggled.connect(_on_gear_button_toggled)
	_settings_button.toggled.connect(_on_settings_button_toggled)

	_close_button.pressed.connect(close)

	(_settings_tab as SettingsTab).exit_to_menu_requested.connect(_on_exit_to_menu_requested)
	(_settings_tab as SettingsTab).quit_requested.connect(_on_quit_requested)

	_show_tab(_stats_tab)
	visible = true # remove before going live

func open(player_data: PlayerData, character_save: CharacterSaveData) -> void:
	_player_data = player_data
	_character_save = character_save
	(_stats_tab as StatsTab).populate(player_data, character_save.active_run)
	(_gear_tab as GearTab).populate(character_save)
	_show_tab(_stats_tab)
	_stats_button.button_pressed = true


func close() -> void:
	visible = false
	closed.emit()

func _show_tab(tab_to_show: Control) -> void:
	for tab_child: Node in _content_stack.get_children():
		tab_child.visible = (tab_child == tab_to_show)

# ── Tab button toggle handlers ─────────────────────────────────────────────────

func _on_stats_button_toggled(is_pressed: bool) -> void:
	if is_pressed:
		_show_tab(_stats_tab)

func _on_gear_button_toggled(is_pressed: bool) -> void:
	if is_pressed:
		_show_tab(_gear_tab)

func _on_settings_button_toggled(is_pressed: bool) -> void:
	if is_pressed:
		_show_tab(_settings_tab)

# ── Save / exit handlers ───────────────────────────────────────────────────────

func _on_exit_to_menu_requested() -> void:
	SaveManager.save()
	exit_to_main_menu_requested.emit()

func _on_quit_requested() -> void:
	SaveManager.save()
	quit_requested.emit()
	get_tree().quit()
