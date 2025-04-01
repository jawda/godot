class_name FootstepAudio2D extends AudioStreamPlayer2D

var stream_randomizer : AudioStreamRandomizer
@export var footstep_variants : Array[ AudioStream ]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stream_randomizer = stream
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_footstep() -> void:
	#dynamically change footstep based on tilemap
	get_footstep_type()
	play()
	pass

func get_footstep_type() -> void:
	for t in get_tree().get_nodes_in_group( "tilemaps" ):
		if t is TileMapLayer:
			if t.tile_set.get_custom_data_layer_by_name("Footstep_type") == -1:
				continue
			#which tile are we on top of
			var cell: Vector2i = t.local_to_map( t.to_local( global_position ) )
			var data : TileData = t.get_cell_tile_data( cell )
			if data:
				var type = data.get_custom_data( "Footstep_type")
				if type == null:
					continue
				stream_randomizer.set_stream( 0,  footstep_variants[ type ] )
				
			pass
		pass
	pass
