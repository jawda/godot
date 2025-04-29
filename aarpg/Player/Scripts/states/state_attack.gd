class_name State_Attack extends State

## used to keep up with if currently attacking
var attacking : bool = false

@export var attack_sound: AudioStream
@export_range(1,20,0.5) var decelerate_speed : float = 5.0

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var charge_attack: State = $"../ChargeAttack"

@onready var attack_anim: AnimationPlayer = $"../../Sprite2D/AttackEffectSprite/AnimationPlayer"
@onready var audio: AudioStreamPlayer2D = $"../../Audio/AudioStreamPlayer2D"
@onready var hurt_box: HurtBox = %AttackHurtBox


## What happens when the player enters this state?
func enter() -> void:
	player.update_animation("attack")
	attack_anim.play("attack_" + player.anim_direction() )
	## connect to a signal for the animation
	animation_player.animation_finished.connect( end_attack )
	audio.stream = attack_sound
	## add some audio attack variance
	audio.pitch_scale = randf_range( 0.9, 1.1 )
	audio.play()
	
	attacking = true
	
	## turn on hurt box monitoring, i.e can i hit something
	## add a little delay for the animation
	await get_tree().create_timer( 0.075 ).timeout
	if attacking:
		hurt_box.monitoring = true
	
	pass

## What happens when the player exits this State?
func exit() -> void:
	## disconnect to a signal for the animation
	animation_player.animation_finished.disconnect( end_attack )
	attacking = false
	
	## turn off hurt box monitoring, i.e can i hit something
	hurt_box.monitoring = false
	pass
	

## What happens during the _process update in this state?
func process( _delta: float ) -> State:
	player.velocity -= player.velocity * decelerate_speed * _delta
	
	if attacking == false:
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk
	
	return null

## What happens during the _physics_process update in this State?
func physics( _delta : float) -> State:
	return null
	

## what happens with input events in this State?
func handle_input( _event: InputEvent ) -> State:
	return null


func end_attack( _newAnimName : String ) -> void:
	if Input.is_action_pressed("attack"):
		state_machine.change_state( charge_attack )
	attacking = false
