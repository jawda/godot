class_name EnemyStateIdle extends EnemyState

@export var anim_name : String = "idle"

##custom catagory setup for this monster
@export_category("AI")
@export var state_duration_min : float = 0.5
@export var state_duration_max : float = 1.5
@export var after_idle_state : EnemyState

var _timer : float = 0.0


## Initialize state
func init() -> void:
	pass

## Enter the state
func enter() -> void:
	enemy.velocity = Vector2.ZERO
	_timer = randf_range( state_duration_min, state_duration_max)
	enemy.update_animation( anim_name )
	pass
	
## Exit the state
func exit() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(_delta: float) -> EnemyState:
	_timer -= _delta
	##idle for set time then change to a new state such as wonder around
	if _timer <= 0:
		return after_idle_state
	return null

func physics( _delta : float) -> EnemyState:
	return null 
