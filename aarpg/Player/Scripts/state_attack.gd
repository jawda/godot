class_name State_Attack extends State

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var attack_anim: AnimationPlayer = $"../../Sprite2D/AttackEffectSprite/AnimationPlayer"

## used to keep up with if currently attacking
var attacking : bool = false
## What happens when the player enters this state?
func Enter() -> void:
	player.UpdateAnimation("attack")
	attack_anim.play("attack_" + player.AnimDirection() )
	## connect to a signal for the animation
	animation_player.animation_finished.connect( EndAttack )
	attacking = true
	pass

## What happens when the player exits this State?
func Exit() -> void:
	## disconnect to a signal for the animation
	animation_player.animation_finished.disconnect( EndAttack )
	attacking = false
	pass
	

## What happens during the _process update in this state?
func Process( _delta: float ) -> State:
	player.velocity = Vector2.ZERO
	
	if attacking == false:
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk
	
	return null

## What happens during the _physics_process update in this State?
func Physics( _delta : float) -> State:
	return null
	

## what happens with input events in this State?
func HandleInput( _event: InputEvent ) -> State:
	return null


func EndAttack( _newAnimName : String ) -> void:
	attacking = false
