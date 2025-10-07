extends CharacterBody2D
 
var speed : float = 150
var health : float = 100.0 :
	set(value):
		health = value
		%Health.value = value
 
func _physics_process(delta):
	velocity = Input.get_vector("left","right","up","down") * speed
	move_and_collide(velocity * delta)
 
	#if velocity == Vector2.ZERO:
		#$AnimationPlayer.play("idle")
	#else:
		#$AnimationPlayer.play("run")
 #
	#if velocity.x < 0:
		#$Sprite2D.flip_h = true
	#elif velocity.x > 0:
		#$Sprite2D.flip_h = false
 #
func take_damage(amount):
	health -= amount
	#print(amount)
 
 
func _on_self_damage_body_entered(body):
	take_damage(body.damage)
 


func _on_timer_timeout() -> void:
	%Collision.set_deferred("disabled", true)
	%Collision.set_deferred("disabled", false)
