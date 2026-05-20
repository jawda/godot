class_name BSPGenerator extends Node

signal new_split_made(areas: Array[Rect2])

@export var minimum_room_size: Vector2 = Vector2(64, 64)
@export var max_depth: int = 6

## Generate subdivisions of rooms and return BSPDungeonInfo
func generate_rooms(size: Vector2) -> BSPDungeonInfo:
	var starting_area: Rect2 = Rect2(Vector2(0, 0), size)
	var result: BSPDungeonInfo = BSPDungeonInfo.new()
	result.root = BSPRoomNode.new(starting_area)

	# Each entry is [node, depth] so we can stop splitting past max_depth.
	var area_queue: Array = [[result.root, 0]]

	#make a queue to create sub divisions 
	while !area_queue.is_empty():
		var entry: Array       = area_queue.pop_front()
		var current_area: BSPRoomNode = entry[0] as BSPRoomNode
		var current_depth: int = entry[1] as int

		#check if we hit max depth yet
		if current_depth >= max_depth:
			continue

		#try and split the room
		var split_rooms: Array[Rect2] = split(current_area.room_info)

		for sub_area: Rect2 in split_rooms:
			var sub_room_node: BSPRoomNode = BSPRoomNode.new(sub_area)
			current_area.sub_division.push_back(sub_room_node)
			area_queue.push_back([sub_room_node, current_depth + 1])

		new_split_made.emit(split_rooms)

	return result

## Given an area of a dungeon split into 2 parts using minimum and maximum room size as guidance.
func split(area: Rect2) -> Array[Rect2]:
	var is_split_vertical: bool = randi_range(0, 1) == 0
	
	var is_too_narrow := area.size.x < 2 * minimum_room_size.x
	var is_too_short := area.size.y < 2 * minimum_room_size.y
	
	if is_too_narrow && is_too_short:
		return []

	if is_too_narrow:
		is_split_vertical = false
	elif is_too_short:
		is_split_vertical = true
		
		
	var result: Array[Rect2] = []
	#choose orientation and then make a split
	if is_split_vertical:
		var split_x_position: int = randi_range(minimum_room_size.x, area.size.x - minimum_room_size.x)
		result.push_back(Rect2(area.position, Vector2(split_x_position, area.size.y)))
		result.push_back(Rect2(area.position + Vector2(split_x_position, 0), Vector2(area.size.x - split_x_position, area.size.y)))
	else:
		var split_y_position: int = randi_range(minimum_room_size.y, area.size.y - minimum_room_size.y)
		result.push_back(Rect2(area.position, Vector2(area.size.x, split_y_position)))
		result.push_back(Rect2(area.position + Vector2(0, split_y_position), Vector2(area.size.x, area.size.y - split_y_position)))

	return result
