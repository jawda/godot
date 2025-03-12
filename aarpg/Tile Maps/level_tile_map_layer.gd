class_name LevelTileMapLayer extends TileMapLayer

@export var tile_size : float = 32

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LevelManager.ChangeTilemapBounds( GetTileMapBounds() )
	pass # Replace with function body.
	
## get top right and bottom left of scene
func GetTileMapBounds() -> Array[ Vector2 ]:
	var bounds : Array[ Vector2 ] = []
	bounds.append(
		Vector2( get_used_rect().position * tile_size) + position
	)
	bounds.append(
		Vector2( get_used_rect().end * tile_size) + position
	)
	return bounds
