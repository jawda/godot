# AutoLoad singleton — no class_name (Godot forbids it on AutoLoad scripts).
extends CanvasLayer

# ── Node references ───────────────────────────────────────────────────────────

@onready var _animation_player: AnimationPlayer = $Overlay/AnimationPlayer

# ── Public API ────────────────────────────────────────────────────────────────

## Fades to black, swaps to scene_path, then fades back in.
## Await this call if you need to know when the fade-in finishes.
func transition_to(scene_path: String) -> void:
	await _fade_out()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await _fade_in()

# ── Private ───────────────────────────────────────────────────────────────────

func _fade_out() -> void:
	_animation_player.play("fade_out")
	await _animation_player.animation_finished

func _fade_in() -> void:
	_animation_player.play("fade_in")
	await _animation_player.animation_finished
