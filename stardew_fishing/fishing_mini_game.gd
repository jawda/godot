extends Control

@onready var fish_box: Control = $Interface/FishBox
@onready var catch_progress: Control = $Interface/CatchProgress
@onready var end_text: Label = $EndText


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed:
		match event.keycode:
			KEY_R:
				get_tree().reload_current_scene()
			KEY_Q:
				get_tree().quit()
			_:
				return
				
func _on_fish_box_fish_in_range(on: bool) -> void:
	catch_progress.increment_value(on)
	pass # Replace with function body.


func _on_catch_progress_fish_caught() -> void:
	end_text.text = "You caught the fish!!\nPress 'R' to restart!"
	end_text.show()
	get_tree().paused = true
	pass # Replace with function body.


func _on_catch_progress_fish_escaped() -> void:
	end_text.text = "The fish escaped!!\nPress 'R' to restart!"
	end_text.show()
	get_tree().paused = true
	pass # Replace with function body.
