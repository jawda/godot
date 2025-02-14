class_name HeartGUI extends Control

@onready var sprite: Sprite2D = $Sprite2D

## 0 is empty heart, 1 is half and 2 is full
var value : int = 2:
	set( _value ):
		value = _value
		update_sprite()


func update_sprite() -> void:
	sprite.frame = value
