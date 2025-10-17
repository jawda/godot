extends Node2D

@export var player : CharacterBody2D
@export var enemy : PackedScene

var distance : float = 400

@export var enemy_types : Array[Enemy]

var minute : int: 
	set(value):
		minute = value
		%Minute.text = str(value)
			
var second : int:
	set(value):
		second = value
		if second >= 10:
			second -= 10
			minute += 1
		%Second.text = str(second).lpad(2, '0')

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#spawn enemies
func spawn(pos : Vector2, elite : bool = false):
	var enemy_instance = enemy.instantiate()
	
	#new enemy every minute
	enemy_instance.type = enemy_types[min(minute, enemy_types.size() -1)]
	
	enemy_instance.position = pos
	enemy_instance.player_reference = player
	enemy_instance.elite = elite
	get_tree().current_scene.add_child(enemy_instance)
	
#get random position from player
func get_random_position() -> Vector2:
	return player.position + distance * Vector2.RIGHT.rotated(randf_range(0,2 * PI))
	
#controls amount of enemies spawned
func amount(number : int = 1):
	for i in range(number):
		spawn(get_random_position())

#increment second and spawn enemies
func _on_timer_timeout() -> void:
	second += 1
	amount(second % 10)


func _on_pattern_timeout() -> void:
	#create a circle when enough enemies appear
	for i in range(75):
		spawn(get_random_position())


func _on_elite_timeout() -> void:
	spawn(get_random_position(), true)
