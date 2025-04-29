class_name EnemyStateWander extends EnemyState

@export var anim_name : String = "walk"
@export var wander_speed : float = 20.0

##custom catagory setup for this monster
@export_category("AI")
@export var state_animation_duration : float = 0.5
@export var state_cycles_min : int = 1
@export var state_cycles_max : int = 3
@export var next_state : EnemyState

var _timer : float = 0.0
var _direction : Vector2

## Initialize state
func init() -> void:
	pass

## Enter the state
func enter() -> void:
	_timer = randi_range( state_cycles_min, state_cycles_max) * state_animation_duration
	
	## get a random direction for the enemy to walk
	var rand = randi_range( 0 , 3)
	_direction = enemy.DIR_4[ rand ]
	enemy.velocity = _direction * wander_speed
	enemy.set_direction( _direction )
	enemy.update_animation( anim_name )
	pass
	
## Exit the state
func exit() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(_delta: float) -> EnemyState:
	_timer -= _delta
	## when the timer goes below zero it then goes to the next state which is assigned in
	## in the custom variable we created
	if _timer < 0:
		return next_state
	return null

func physics( _delta : float) -> EnemyState:
	return null 
