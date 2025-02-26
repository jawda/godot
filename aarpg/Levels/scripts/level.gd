class_name Level extends Node2D

@export var music : AudioStream

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.y_sort_enabled = true
	PlayerManager.set_as_parent( self ) # Replace with function body.
	LevelManager.level_load_started.connect( _free_level )
	AudioManager.play_music( music )

func _free_level() -> void:
	PlayerManager.unparent_player( self )
	queue_free()
