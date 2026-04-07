class_name StartScreen
extends Control

const CHARACTER_SELECT_SCENE: String = "res://gui/character_select/character_select.tscn"

# ── Node references ───────────────────────────────────────────────────────────

@onready var _new_game_button: Button  = %NewGame
@onready var _continue_button: Button  = %Continue
@onready var _settings_button: Button  = %Settings
@onready var _quit_button: Button      = %Quit

# ── Runtime ───────────────────────────────────────────────────────────────────

var _settings_overlay: Control = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Continue is only shown when at least one character run has been started.
	_continue_button.visible = not SaveManager.save_data.character_saves.is_empty()

	_new_game_button.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	_settings_overlay = _build_settings_overlay()
	add_child(_settings_overlay)

# ── Button handlers ───────────────────────────────────────────────────────────

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)

func _on_continue_pressed() -> void:
	# Save loading not yet wired — goes to character select same as New Game.
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)

func _on_settings_pressed() -> void:
	_settings_overlay.show()

func _on_quit_pressed() -> void:
	get_tree().quit()

# ── Settings overlay ──────────────────────────────────────────────────────────

## Builds a full-screen overlay wrapping the existing SettingsTab scene.
## Created once in _ready and shown/hidden as needed.
func _build_settings_overlay() -> Control:
	var overlay: Control = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.hide()

	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay.add_child(backdrop)

	var screen_center: CenterContainer = CenterContainer.new()
	screen_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(screen_center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 480)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.04, 0.12, 0.97)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(0.44, 0.22, 0.66, 0.80)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", panel_style)
	screen_center.add_child(panel)

	var settings_scene: PackedScene = preload("res://gui/character_menu/tabs/settings_menu.tscn")
	var settings_node: SettingsTab = settings_scene.instantiate() as SettingsTab
	settings_node.exit_to_menu_requested.connect(func() -> void: overlay.hide())
	settings_node.quit_requested.connect(func() -> void: get_tree().quit())
	panel.add_child(settings_node)

	return overlay
