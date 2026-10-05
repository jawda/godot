extends Node2D
## Temporary demo harness for the dialog system.
##
## This is not part of the real game — it exists only to test the ported balloon
## before there is a player or world to trigger dialog from. Press 1 for a
## two-character scene with a branching choice, or 2 for a single-character scene.
## While dialog is showing, Enter/Space advances and the arrow keys + Enter pick a
## choice. Once the world and an interaction system exist, those will call
## DialogSystem.start() instead of this scene.

const MULTI_CHARACTER_PATH: String = "res://dialog/scripts/intro.dialogue"
const SINGLE_CHARACTER_PATH: String = "res://dialog/scripts/solo.dialogue"

func _unhandled_input(event: InputEvent) -> void:
	# Ignore start keys while a conversation is already running — the balloon
	# (which keeps processing during the pause) handles input from then on.
	if DialogSystem.is_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			DialogSystem.start(load(MULTI_CHARACTER_PATH), "start")
		elif event.keycode == KEY_2:
			DialogSystem.start(load(SINGLE_CHARACTER_PATH), "start")
