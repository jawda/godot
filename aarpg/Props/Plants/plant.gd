class_name Plant extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HitBox.damaged.connect( take_damage )

	pass # Replace with function body.

##queue up the node for removal since only need one swipe to destroy
func take_damage(hurt_box : HurtBox) -> void:
	animation_player.play("destroy")
	await animation_player.animation_finished
	queue_free()
	pass
