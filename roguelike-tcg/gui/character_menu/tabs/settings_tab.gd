class_name SettingsTab
extends Control

const SETTINGS_PATH: String = "user://settings.cfg"
const AUDIO_SECTION: String = "audio"
const DISPLAY_SECTION: String = "display"

# ── Signals ────────────────────────────────────────────────────────────────────

signal exit_to_menu_requested
signal quit_requested

# ── Node references ────────────────────────────────────────────────────────────

@onready var _master_slider: HSlider = $ContentBox/AudioSectionMargin/AudioSectionPanel/AudioSection/MasterRow/MasterSlider
@onready var _master_value: Label = $ContentBox/AudioSectionMargin/AudioSectionPanel/AudioSection/MasterRow/MasterValue
@onready var _music_slider: HSlider = $ContentBox/AudioSectionMargin/AudioSectionPanel/AudioSection/MusicRow/MusicSlider
@onready var _music_value: Label = $ContentBox/AudioSectionMargin/AudioSectionPanel/AudioSection/MusicRow/MusicValue
@onready var _sfx_slider: HSlider = $ContentBox/AudioSectionMargin/AudioSectionPanel/AudioSection/SFXRow/SFXSlider
@onready var _sfx_value: Label = $ContentBox/AudioSectionMargin/AudioSectionPanel/AudioSection/SFXRow/SFXValue
@onready var _fullscreen_toggle: CheckButton = $ContentBox/DisplaySectionMargin/DisplaySectionPanel/DisplaySection/FullscreenRow/FullscreenToggle
@onready var _exit_to_menu_button: Button = $ContentBox/ExitQuitMargin/ExitQuitButtons/ExitToMenuButton
@onready var _quit_button: Button = $ContentBox/ExitQuitMargin/ExitQuitButtons/QuitButton


func _ready() -> void:
	var config: ConfigFile = ConfigFile.new()
	var load_error: Error = config.load(SETTINGS_PATH)

	var master_percent: float = 100.0
	var music_percent: float = 80.0
	var sfx_percent: float = 100.0
	var is_fullscreen: bool = false

	if load_error == OK:
		master_percent = config.get_value(AUDIO_SECTION, "master", 100.0)
		music_percent = config.get_value(AUDIO_SECTION, "music", 80.0)
		sfx_percent = config.get_value(AUDIO_SECTION, "sfx", 100.0)
		is_fullscreen = config.get_value(DISPLAY_SECTION, "fullscreen", false)

	_master_slider.value = master_percent
	_master_value.text = str(int(master_percent))
	_music_slider.value = music_percent
	_music_value.text = str(int(music_percent))
	_sfx_slider.value = sfx_percent
	_sfx_value.text = str(int(sfx_percent))
	_fullscreen_toggle.button_pressed = is_fullscreen

	_apply_audio_volume("Master", master_percent)
	_apply_audio_volume("Music", music_percent)
	_apply_audio_volume("SFX", sfx_percent)
	_apply_display_mode(is_fullscreen)

	_master_slider.value_changed.connect(_on_master_slider_value_changed)
	_music_slider.value_changed.connect(_on_music_slider_value_changed)
	_sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggle_toggled)
	_exit_to_menu_button.pressed.connect(_on_exit_to_menu_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)

func _apply_audio_volume(bus_name: String, linear_percent: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_percent / 100.0))

func _apply_display_mode(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(AUDIO_SECTION, "master", _master_slider.value)
	config.set_value(AUDIO_SECTION, "music", _music_slider.value)
	config.set_value(AUDIO_SECTION, "sfx", _sfx_slider.value)
	config.set_value(DISPLAY_SECTION, "fullscreen", _fullscreen_toggle.button_pressed)
	config.save(SETTINGS_PATH)

func _on_master_slider_value_changed(new_value: float) -> void:
	_master_value.text = str(int(new_value))
	_apply_audio_volume("Master", new_value)
	_save_settings()

func _on_music_slider_value_changed(new_value: float) -> void:
	_music_value.text = str(int(new_value))
	_apply_audio_volume("Music", new_value)
	_save_settings()

func _on_sfx_slider_value_changed(new_value: float) -> void:
	_sfx_value.text = str(int(new_value))
	_apply_audio_volume("SFX", new_value)
	_save_settings()

func _on_fullscreen_toggle_toggled(is_pressed: bool) -> void:
	_apply_display_mode(is_pressed)
	_save_settings()

func _on_exit_to_menu_button_pressed() -> void:
	exit_to_menu_requested.emit()

func _on_quit_button_pressed() -> void:
	quit_requested.emit()
