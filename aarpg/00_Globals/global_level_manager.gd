extends Node

signal level_load_started
signal level_loaded
signal TileMapBoundsChanged( bounds : Array[ Vector2 ] )

var current_tilemap_bounds : Array[ Vector2 ]
var target_transition : String
var position_offset : Vector2

func _ready() -> void:
	await get_tree().process_frame
	level_loaded.emit()

func ChangeTilemapBounds(bounds : Array[ Vector2 ] ) -> void:
	current_tilemap_bounds = bounds
	TileMapBoundsChanged.emit( bounds )

func load_new_level(
		level_path : String,
		_target_transition : String,
		_position_offset : Vector2
) -> void:
	get_tree().paused = true
	target_transition = _target_transition
	position_offset = _position_offset
	
	## wait for next process tick
	await get_tree().process_frame  # Level Transition
	
	level_load_started.emit()
	
	##wait for the next process tick to give time to load
	await get_tree().process_frame
	get_tree().change_scene_to_file( level_path )
	## transition happens then we unpause
	
	## wait for next process tick
	await get_tree().process_frame  # Level Transition
	get_tree().paused = false
	
	## wait for next process tick
	await get_tree().process_frame
	## say level is now loaded
	level_loaded.emit()
	pass
