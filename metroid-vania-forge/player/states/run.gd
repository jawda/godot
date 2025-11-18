class_name PlayerStateRun extends PlayerState

# What happens when this state is initialized
func init() -> void:
	
	pass
	
# What happens when we enter this state	
func enter() -> void:
	player.animation_player.play( "run" )
	pass
	
#what happens when we exit this state
func exit() -> void:
	
	pass

#  What happens when an input is pressed or released?
func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "jump" ):
		return jump
	return next_state
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(_delta: float) -> PlayerState:
	if player.direction.x == 0:
		return idle
	elif player.direction.y > 0.5:
		return crouch
	return next_state

func physics_process(_delta: float) -> PlayerState:
	player.velocity.x = player.direction.x * player.move_speed
	if player.is_on_floor() == false:
		return fall
	return next_state
