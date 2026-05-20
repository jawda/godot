class_name SaveTab
extends Control

# ── Signals ────────────────────────────────────────────────────────────────────

signal exit_to_menu_requested
signal quit_requested

# ── Node references ────────────────────────────────────────────────────────────

@onready var _exit_to_menu_button: Button = $ContentBox/ExitToMenuButton
@onready var _quit_button: Button = $ContentBox/QuitButton

func _ready() -> void:
	_exit_to_menu_button.pressed.connect(_on_exit_to_menu_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)

func _on_exit_to_menu_button_pressed() -> void:
	exit_to_menu_requested.emit()

func _on_quit_button_pressed() -> void:
	quit_requested.emit()
