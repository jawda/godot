class_name DrunkardsDungeonVisualizer extends Node2D
@onready var drunkards_walk_generator: DrunkardsWalkGenerator = $DrunkardsWalkGenerator

@export var map_size: Vector2i = Vector2i(1280, 720)
@export var primary_color : Color = Color.WEB_GREEN
@export var secondary_color : Color = Color.DARK_GREEN

var map : Array[Array]
var map_img : ImageTexture
var position_queue : Array[Vector2i] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#currnt screen 1280x720
	map = drunkards_walk_generator.generate(map_size)
	var img := Image.create_empty(map_size.x, map_size.y, false, Image.FORMAT_RGBA8)
	
	for i in map.size():
		for j in map[i].size():
			img.set_pixel(i, j, primary_color)
			
	map_img = ImageTexture.create_from_image(img)
	
	
func _draw():
	if !map:
		return
	draw_texture_rect(map_img, Rect2(0,0,1280,720 ), false)


func _on_update_timer_timeout() -> void:
	if position_queue.is_empty():
		return
	var new_img = map_img.get_image()
	
	for i in 50:
		if position_queue.is_empty():
			break
		var carved_position : Vector2i = position_queue.pop_front()
		new_img.set_pixel(carved_position.x, carved_position.y, secondary_color)
	map_img = ImageTexture.create_from_image(new_img)
	queue_redraw()
	pass # Replace with function body.


func _on_drunkards_walk_generator_new_position_carved(pos: Vector2i) -> void:
	position_queue.push_back(pos)
	pass # Replace with function body.
