extends Control


signal fish_in_range(on: bool)

@export var fish_speed : float = 0.1
@export var min_jump_delay: float = 0.6
@export var max_jump_delay: float = 2.5
@export var catch_bar_weight: float = 0.05
@onready var fill: ColorRect = $Border/MarginContainer/Fill
@onready var fish_icon: TextureRect = $Border/MarginContainer/Fill/FishIcon
@onready var catch_bar: ColorRect = $Border/MarginContainer/Fill/CatchBar
@onready var y_range: int = fill.size.y
@onready var fish_move: Timer = $FishMove
var fish_target_y : int = 0

func _ready() -> void:
	update_fish_target()
	
func _process(delta: float) -> void:
	#move fish to its target
	fish_icon.position.y = lerpf(fish_icon.position.y, fish_target_y, fish_speed)
	
	#move catch bar
	var catch_bar_top : float = catch_bar.position.y
	if Input.is_action_pressed("ui_accept"):
		catch_bar.position.y = max(0.0, catch_bar.position.y - 1) 
	else:
		catch_bar.position.y = lerpf(catch_bar.position.y, y_range - catch_bar.size.y, catch_bar_weight)
	
	#check if catch bar is within range of fish	
	var fish_y : float = fish_icon.position.y 
	fish_in_range.emit( fish_y > catch_bar_top and fish_y < catch_bar_top + catch_bar.size.y )
		

func update_fish_target() -> void:
	fish_target_y = randi() % y_range
	fish_move.start(randf_range(min_jump_delay,max_jump_delay))

func _on_fish_move_timeout() -> void:
	update_fish_target()
	
	pass 
