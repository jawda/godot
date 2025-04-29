class_name LevelTileMap extends TileMap


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LevelManager.ChangeTilemapBounds( GetTileMapBounds() )
	pass # Replace with function body.
	
## get top right and bottom left of scene
func GetTileMapBounds() -> Array[ Vector2 ]:
	var bounds : Array[ Vector2 ] = []
	bounds.append(
		Vector2( get_used_rect().position * rendering_quadrant_size)
	)
	bounds.append(
		Vector2( get_used_rect().end * rendering_quadrant_size)
	)
	return bounds
