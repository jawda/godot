class_name EnemyStateStun extends EnemyState

@export var anim_name : String = "stun"
@export var knockback_speed : float = 200.0
@export var decelerate_speed : float = 10.0

##custom catagory setup for this monster
@export_category("AI")
@export var next_state : EnemyState

var _direction : Vector2
var _animation_finished : bool = false

## Initialize state
## connect the damage trigger
func init() -> void:
	enemy.enemy_damaged.connect( _on_enemy_damaged )
	pass

## Enter the state
func enter() -> void:
	enemy.invulnerable = true
	_animation_finished = false
	## get a random direction for the enemy to walk
	#var rand = randi_range( 0 , 3)
	## get the direction of the player
	_direction = enemy.global_position.direction_to( enemy.player.global_position )
	
	## now we knock the enemy back away from the player a little
	enemy.set_direction( _direction )
	enemy.velocity = _direction * -knockback_speed
	
	enemy.update_animation( anim_name )
	enemy.animation_player.animation_finished.connect( _on_animation_finished )
	pass
	
## Exit the state
func exit() -> void:
	enemy.invulnerable = false
	enemy.animation_player.animation_finished.disconnect(_on_animation_finished)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
## ease to slow when stun
func process(_delta: float) -> EnemyState:
	if _animation_finished == true:
		return next_state
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	return null

func physics( _delta : float) -> EnemyState:
	return null 
	
## if we get the signal from the enemy script that damage happened
## set the stun state
func _on_enemy_damaged() -> void:
	state_machine.change_state( self )
	
func _on_animation_finished( _a : String ) -> void:
	_animation_finished = true
