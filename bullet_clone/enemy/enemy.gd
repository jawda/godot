extends CharacterBody2D

@export var player_reference : CharacterBody2D

var speed : float = 75.0
var direction : Vector2
var damage : float

var elite : bool = false:
	#make the elite special with a shader
	set(value):
		elite = value
		if value:
			$Sprite2D.material = load("res://shaders/Rainbow.tres")
			scale = Vector2(1.5, 1.5)
			#can increase health and damage here
		
var type : Enemy:
	set(value):
		type = value
		$Sprite2D.texture = value.texture
		damage = value.damage

func _physics_process(delta: float) -> void:
	#move toward player
	velocity = (player_reference.position - position).normalized() * speed
	move_and_collide(velocity * delta)
	pass
