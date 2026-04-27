class_name StartScreen
extends Control

const CHARACTER_SELECT_SCENE: String = "res://gui/character_select/character_select.tscn"

# ── Node references ───────────────────────────────────────────────────────────

@onready var _new_game_button: Button    = %NewGame
@onready var _continue_button: Button   = %Continue
@onready var _settings_button: Button   = %Settings
@onready var _quit_button: Button       = %Quit
@onready var _settings_overlay: Control = $SettingsOverlay
@onready var _settings_tab: SettingsTab = $SettingsOverlay/Centered/Dialog/SettingsMenu

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Continue is only shown when at least one character run has been started.
	_continue_button.visible = not SaveManager.save_data.character_saves.is_empty()

	_new_game_button.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	_settings_tab.exit_to_menu_requested.connect(func() -> void: _settings_overlay.hide())
	_settings_tab.quit_requested.connect(func() -> void: get_tree().quit())

	_setup_focus_neighbors()
	_new_game_button.grab_focus()

# ── Focus / keyboard navigation ──────────────────────────────────────────────

## Wires arrow-key focus neighbors so the menu is fully keyboard-navigable.
## Called after Continue's visibility is decided, because it may be hidden.
func _setup_focus_neighbors() -> void:
	var visible_buttons: Array[Button] = []
	visible_buttons.append(_new_game_button)
	if _continue_button.visible:
		visible_buttons.append(_continue_button)
	visible_buttons.append(_settings_button)
	visible_buttons.append(_quit_button)

	var button_count: int = visible_buttons.size()
	for button_index: int in range(button_count):
		var above: Button = visible_buttons[(button_index - 1 + button_count) % button_count]
		var below: Button = visible_buttons[(button_index + 1) % button_count]
		visible_buttons[button_index].focus_neighbor_top = visible_buttons[button_index].get_path_to(above)
		visible_buttons[button_index].focus_neighbor_bottom = visible_buttons[button_index].get_path_to(below)

# ── Button handlers ───────────────────────────────────────────────────────────

func _on_new_game_pressed() -> void:
	SceneTransition.transition_to(CHARACTER_SELECT_SCENE)

func _on_continue_pressed() -> void:
	# Save loading not yet wired — goes to character select same as New Game.
	SceneTransition.transition_to(CHARACTER_SELECT_SCENE)

func _on_settings_pressed() -> void:
	_settings_overlay.show()

func _on_quit_pressed() -> void:
	get_tree().quit()
