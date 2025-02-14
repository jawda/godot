class_name Plant extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HitBox.damaged.connect( take_damage )

	pass # Replace with function body.

##queue up the node for removal since only need one swipe to destroy
func take_damage( _damage : int) -> void:
	queue_free()
	pass
