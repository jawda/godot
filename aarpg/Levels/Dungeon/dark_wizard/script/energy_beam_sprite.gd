extends Sprite2D

@export var speed : float = 100

var rect : Rect2

func _ready() -> void:
	rect = self.region_rect
	pass
	
func _process(delta: float) -> void:
	region_rect.position += Vector2( speed * delta, 0 )#adjust x to make pan
	pass
