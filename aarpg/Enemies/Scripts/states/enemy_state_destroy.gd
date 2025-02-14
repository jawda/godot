class_name EnemyStateDestroy extends EnemyState

@export var anim_name : String = "destroy"
@export var knockback_speed : float = 200.0
@export var decelerate_speed : float = 10.0

##custom catagory setup for this monster
@export_category("AI")

var _damage_position : Vector2
var _direction : Vector2

## Initialize state
## connect the damage trigger
func init() -> void:
	enemy.enemy_destroyed.connect( _on_enemy_destroyed )
	pass

## Enter the state
func enter() -> void:
	enemy.invulnerable = true
	## get a random direction for the enemy to walk
	#var rand = randi_range( 0 , 3)
	## get the direction of the player
	_direction = enemy.global_position.direction_to( _damage_position )
	
	## now we knock the enemy back away from the player a little
	enemy.set_direction( _direction )
	enemy.velocity = _direction * -knockback_speed
	
	enemy.update_animation( anim_name )
	enemy.animation_player.animation_finished.connect( _on_animation_finished )
	pass
	
## Exit the state
func exit() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
## ease to slow when stun
func process(_delta: float) -> EnemyState:
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	return null

func physics( _delta : float) -> EnemyState:
	return null 
	
## if we get the signal from the enemy script that damage happened
## set the stun state
func _on_enemy_destroyed( hurt_box : HurtBox ) -> void:
	_damage_position = hurt_box.global_position
	state_machine.change_state( self )
	
func _on_animation_finished( _a : String ) -> void:
	enemy.queue_free()
