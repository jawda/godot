class_name FloorMap
extends Control

## Top-down dungeon floor map. Renders a FloorMapData as a flowchart layout
## and lets the player navigate by clicking reachable rooms.
##
## Usage:
##   floor_map.refresh(floor_map_data, "Floor 1 — The Crypt")
##   floor_map.room_selected.connect(_on_room_selected)
##
## The caller is responsible for updating FloorMapData (marking rooms visited,
## advancing current_room_index) and calling refresh() again after each move.
## The map scrolls horizontally — room sizes stay fixed regardless of column count.

# ── Constants ──────────────────────────────────────────────────────────────────

const ROOM_NODE_SCENE: PackedScene = preload("res://gui/floor_map/room_node.tscn")

# ── Signals ─────────────────────────────────────────────────────────────────────

## Emitted when the player clicks a reachable room.
signal room_selected(room_index: int)

# ── Node references ─────────────────────────────────────────────────────────────

@onready var _floor_title: Label = $FloorTitle
@onready var _map_content: Control = $ScrollContainer/MapContent
@onready var _corridor_layer: CorridorLayer = $ScrollContainer/MapContent/CorridorLayer
@onready var _room_layer: Control = $ScrollContainer/MapContent/RoomLayer

# ── Public API ─────────────────────────────────────────────────────────────────

## Rebuild the map display from the current state of floor_map_data.
## Call this on initial load and after each room is resolved.
func refresh(floor_map_data: FloorMapData, floor_name: String = "") -> void:
	if floor_map_data == null:
		return
	_floor_title.text = floor_name
	_resize_map_content(floor_map_data.rooms)
	_rebuild_corridors(floor_map_data)
	_rebuild_rooms(floor_map_data)

# ── Private ────────────────────────────────────────────────────────────────────

## Size the scrollable canvas to fit all rooms. Width grows with column count;
## height matches CANVAS_HEIGHT so the map fills the viewport vertically.
func _resize_map_content(rooms: Array[RoomData]) -> void:
	var max_x: float = 0.0
	for room: RoomData in rooms:
		var right_edge: float = float(room.position.x) + float(room.size.x)
		if right_edge > max_x:
			max_x = right_edge
	var content_width: float = max_x + FloorMapGenerator.MARGIN_X
	var content_height: float = FloorMapGenerator.CANVAS_HEIGHT
	_map_content.custom_minimum_size = Vector2(content_width, content_height)

func _rebuild_corridors(floor_map_data: FloorMapData) -> void:
	var pairs: Array = []
	var drawn_pairs: Dictionary[String, bool] = {}
	var rooms: Array[RoomData] = floor_map_data.rooms

	for room_index: int in rooms.size():
		var room: RoomData = rooms[room_index]
		var room_center: Vector2 = Vector2(room.position) + Vector2(room.size) * 0.5

		for connected_index: int in room.connected_room_indices:
			var pair_key: String = "%d_%d" % [mini(room_index, connected_index), maxi(room_index, connected_index)]
			if drawn_pairs.has(pair_key):
				continue
			drawn_pairs[pair_key] = true
			var connected_room: RoomData = rooms[connected_index]
			var connected_center: Vector2 = Vector2(connected_room.position) + Vector2(connected_room.size) * 0.5
			pairs.append([room_center, connected_center])

	_corridor_layer.set_corridors(pairs)

func _rebuild_rooms(floor_map_data: FloorMapData) -> void:
	for child: Node in _room_layer.get_children():
		child.queue_free()

	var reachable_indices: Array[int] = _reachable_room_indices(floor_map_data)

	for room_index: int in floor_map_data.rooms.size():
		var room: RoomData = floor_map_data.rooms[room_index]
		var display_state: RoomNode.DisplayState = _display_state_for(
			room, room_index, floor_map_data.current_room_index, reachable_indices)

		var room_node: RoomNode = ROOM_NODE_SCENE.instantiate() as RoomNode
		_room_layer.add_child(room_node)
		room_node.position = Vector2(room.position)
		room_node.setup(room, room_index, display_state)
		room_node.room_clicked.connect(_on_room_clicked)

func _reachable_room_indices(floor_map_data: FloorMapData) -> Array[int]:
	var reachable: Array[int] = []

	if floor_map_data.current_room_index < 0:
		# Floor not yet entered — only the start room is reachable
		reachable.append(floor_map_data.start_room_index)
		return reachable

	var current_room: RoomData = floor_map_data.get_current_room()
	if current_room == null:
		return reachable

	for connected_index: int in current_room.connected_room_indices:
		var connected_room: RoomData = floor_map_data.get_room(connected_index)
		if connected_room == null or connected_room.visited:
			continue
		# Only allow forward movement — connections are bidirectional for corridor
		# drawing, so explicitly reject anything to the left of the current room.
		if connected_room.position.x <= current_room.position.x:
			continue
		reachable.append(connected_index)

	return reachable

func _display_state_for(
		room: RoomData,
		room_index: int,
		current_room_index: int,
		reachable_indices: Array[int]) -> RoomNode.DisplayState:
	if room_index == current_room_index:
		return RoomNode.DisplayState.CURRENT
	if room.visited:
		return RoomNode.DisplayState.VISITED
	if room_index in reachable_indices:
		return RoomNode.DisplayState.REACHABLE
	return RoomNode.DisplayState.LOCKED

func _on_room_clicked(room_index: int) -> void:
	room_selected.emit(room_index)
