extends Control

signal fish_caught()
signal fish_escaped()

@onready var progress_bar: ProgressBar = $Border/MarginContainer/ProgressBar

func increment_value(on : bool) -> void:
	if on:
		progress_bar.value += 3
		if progress_bar.value >= progress_bar.max_value:
			fish_caught.emit()
			
	else:
		progress_bar.value += 1 
		if progress_bar.value <= 0:
			fish_escaped.emit()
			
	
	
