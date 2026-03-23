class_name PlayerStateCrouch extends PlayerState

@export var deceleration_rate : float = 10
# What happens when this state is initialized
func init() -> void:
	
	pass
	
# What happens when we enter this state	
func enter() -> void:
	#play animation
	player.animation_player.play( "crouch" )
	player.collision_stand.disabled = true
	player.collision_crouch.disabled = false
	pass
	
#what happens when we exit this state
func exit() -> void:
	player.collision_stand.disabled = false
	player.collision_crouch.disabled = true
	pass

#  What happens when an input is pressed or released?
func handle_input( _event : InputEvent ) -> PlayerState:
	#handle inputs
	if _event.is_action_pressed( "jump" ):
		player.one_way_platform_shape_cast.force_shapecast_update()
		if player.one_way_platform_shape_cast.is_colliding():
			player.position.y += 4
			return fall
		return jump
	return next_state
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(_delta: float) -> PlayerState:
	if player.direction.y <= 0.5:
		return idle
	return next_state

func physics_process(_delta: float) -> PlayerState:
	player.velocity.x -= player.velocity.x * deceleration_rate * _delta
	if player.is_on_floor() == false:
		return fall
	return next_state
