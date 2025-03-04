class_name State_Carry extends State

@export var move_speed : float = 100.0
@export var throw_audio : AudioStream

var walking : bool = false
var throwable : Throwable

@onready var idle: State_Idle = $"../Idle"
@onready var stun: State_Stun = $"../Stun"



func _ready():
	pass
	
func init() -> void:
	pass
	
## What happens when the player enters this state?
func enter() -> void:
	player.update_animation( "carry" )
	walking = false
	pass

## What happens when the player exits this State?
func exit() -> void:
	#throw object
	if throwable:
		# throw direction
		if player.direction == Vector2.ZERO:
			throwable.throw_direction = player.cardinal_direction
		else:
			throwable.throw_direction = player.direction
			
		#were we stunned if so drop
		if state_machine.next_state == stun:
			throwable.throw_direction = throwable.throw_direction.rotated( PI )
			throwable.drop()
			pass
		#else throw item
		else: 
			player.audio.stream = throw_audio
			player.audio.play()
			throwable.throw()
			pass
		pass
	pass
	

## What happens during the _process update in this state?
func process( _delta: float ) -> State:
	#are we walking or standing?
	if player.direction == Vector2.ZERO:
		walking = false
		player.update_animation("carry")
	elif player.set_direction() or walking == false:
		player.update_animation("carry_walk")
		walking = true
	
	player.velocity = player.direction * move_speed
	return null

## What happens during the _physics_process update in this State?
func physics( _delta : float) -> State:
	return null
	

## what happens with input events in this State?
func handle_input( _event: InputEvent ) -> State:
	if _event.is_action_pressed("attack") or _event.is_action_pressed("interact"):
		return idle
	return null
