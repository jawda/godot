@tool
class_name LevelTransition extends Area2D

## tool above allows this script to run in the editor

enum SIDE { LEFT, RIGHT, TOP, BOTTOM }

## limit file types to scene files
@export_file( "*.tscn" ) var level
## used to point the player to the other map
@export var target_transition_area : String = "LevelTransition"
@export_category("Collision Area Settings")

@export_range(1, 12, 1, "or_greater" ) var size : int = 2:
	set( _v ):
		size = _v
		_update_area()
		
@export var side: SIDE = SIDE.LEFT :
	set( _v ):
		side = _v
		_update_area()
		
@export var snap_to_grid: bool = false :
	set ( _v ):
		_snap_to_grid()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_area()
	pass # Replace with function body.

func _update_area() -> void:
	var new_rect : Vector2 = Vector2( 32,32 )
	var new_position : Vector2 = Vector2.ZERO
	
	if side == SIDE.TOP:
		new_rect.x *= size
		new_position.y -= 16
	elif side == SIDE.BOTTOM:
		new_rect.x *= size
		new_position.y += 16
	elif side == SIDE.LEFT:
		new_rect.y *= size
		new_position.x -= 16
	elif side == SIDE.RIGHT:
		new_rect.y *= size
		new_position.x += 16
		
	if collision_shape == null:
		collision_shape = get_node("CollisionShape2D")
	
	collision_shape.shape.size = new_rect
	collision_shape.position = new_position

func _snap_to_grid() -> void:
	position.x = round( position.x / 16 ) * 16
	position.y = round( position.y / 16 ) * 16
