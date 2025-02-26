class_name Boomerang extends Node2D

enum State { INACTIVE, THROW, RETURN }

var player : Player
var direction : Vector2
var speed : float = 0
var state 

@export var acceleration : float = 500.0
@export var max_speed : float = 400.0
@export var catch_audio : AudioStream

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	visible = false
	state = State.INACTIVE
	player = PlayerManager.player
	
func _physics_process(delta: float) -> void:
	if state == State.THROW:
		speed -= acceleration * delta #have it gradually slow
		position += direction * speed * delta
		if speed <= 0:
			state = State.RETURN
		pass
	elif state == State.RETURN:
		direction = global_position.direction_to( player.global_position )#find player
		speed += acceleration * delta
		position += direction * speed * delta
		if global_position.direction_to( player.global_position ) <= Vector2.ZERO:
			PlayerManager.play_audio(catch_audio)
			queue_free()#it has returned so remove it
		pass
		
	var speed_ratio = speed / max_speed
	audio.pitch_scale = speed_ratio * 0.75 + 0.75 #give some dynamic audio pitch scaling
	
	animation_player.speed_scale = 1 + (speed_ratio * 0.25)
	pass
	
func throw( throw_direction : Vector2 ) -> void:
	direction = throw_direction
	speed = max_speed
	state = State.THROW
	animation_player.play("boomerang")
	PlayerManager.play_audio(catch_audio)
	visible = true
	pass
