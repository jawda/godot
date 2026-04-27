class_name FloorLoop
extends Control

## Top-level scene for navigating a dungeon floor.
##
## Alternates between two modes:
##   MAP  — FloorMap visible; player picks a room to enter.
##   ROOM — A room scene fills the screen; player resolves the room.
##
## Room scenes are instanced into RoomView and freed when resolved.
## All run state lives in RunState (autoload); this scene is purely the router.

# ── Scene preloads ──────────────────────────────────────────────────────────────

const BATTLEFIELD_SCENE: PackedScene      = preload("res://gui/battlefield.tscn")
const REST_SITE_SCENE: PackedScene        = preload("res://gui/rest_site/rest_site.tscn")
const SHOP_SCENE: PackedScene             = preload("res://gui/shop/shop.tscn")
const SHELL_GAME_SCENE: PackedScene       = preload("res://gui/events/shell_game/shell_game_event.tscn")
const ROOM_PLACEHOLDER_SCENE: PackedScene = preload("res://gui/floor_loop/room_placeholder.tscn")

# ── Node references ─────────────────────────────────────────────────────────────

@onready var _map_view: Control = $MapView
@onready var _floor_map: FloorMap = $MapView/FloorMap
@onready var _room_view: Control = $RoomView

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_floor_map.room_selected.connect(_on_room_selected)
	_enter_map()

# ── Map mode ───────────────────────────────────────────────────────────────────

func _enter_map() -> void:
	for child: Node in _room_view.get_children():
		child.queue_free()
	_room_view.hide()
	_map_view.show()

	var floor_map_data: FloorMapData = RunState.active_run.floor_map

	# Auto-enter the START room so the player never has to click it.
	# The START room exists only as a graph anchor — clicking it adds no value.
	if floor_map_data.current_room_index < 0:
		var start_room: RoomData = floor_map_data.get_start_room()
		if start_room != null:
			start_room.visited = true
			floor_map_data.current_room_index = floor_map_data.start_room_index

	var floor_data: FloorData = RunState.get_current_floor_data()
	var floor_name: String = ""
	if floor_data != null:
		floor_name = "Floor %d — %s" % [RunState.active_run.current_floor, floor_data.floor_name]
	_floor_map.refresh(floor_map_data, floor_name)

func _on_room_selected(room_index: int) -> void:
	var floor_map_data: FloorMapData = RunState.active_run.floor_map
	var room: RoomData = floor_map_data.get_room(room_index)
	if room == null:
		return

	room.visited = true
	floor_map_data.current_room_index = room_index
	SaveManager.save()
	_enter_room(room, room_index)

# ── Room mode ──────────────────────────────────────────────────────────────────

func _enter_room(room: RoomData, room_index: int) -> void:
	_map_view.hide()
	_room_view.show()

	var room_scene: Node = _instantiate_room_scene(room)
	_room_view.add_child(room_scene)

	# Godot defers Control layout recalculation to the next frame. If we don't
	# force the layout here, all button hit-areas resolve to zero size/position
	# until something else (like opening the DeckViewer) triggers a recalc.
	if room_scene is Control:
		(room_scene as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_connect_room_signal(room_scene, room, room_index)

## Instantiates and fully configures the scene for the given room type.
## Battlefield receives its data before add_child so _ready() can start combat.
## Other scenes (with @onready vars) are configured after add_child via _connect_room_signal.
func _instantiate_room_scene(room: RoomData) -> Node:
	match room.room_type:
		RoomData.RoomType.COMBAT, RoomData.RoomType.ELITE, RoomData.RoomType.BOSS:
			var battlefield: Battlefield = BATTLEFIELD_SCENE.instantiate() as Battlefield
			battlefield.player_data = RunState.active_player
			battlefield.enemy_data_list = _enemies_for_room(room)
			battlefield.room_type = room.room_type
			return battlefield
		RoomData.RoomType.REST:
			return REST_SITE_SCENE.instantiate()
		RoomData.RoomType.SHOP:
			return SHOP_SCENE.instantiate()
		RoomData.RoomType.EVENT:
			return SHELL_GAME_SCENE.instantiate()
		# TODO: replace stubs as each room type is built:
		# RoomData.RoomType.TREASURE:   return TREASURE_SCENE.instantiate()
		# RoomData.RoomType.BLACKSMITH: return BLACKSMITH_SCENE.instantiate()
	return ROOM_PLACEHOLDER_SCENE.instantiate()

## Connect the room scene's completion signal after it is in the scene tree.
func _connect_room_signal(room_scene: Node, room: RoomData, room_index: int) -> void:
	if room_scene is Battlefield:
		(room_scene as Battlefield).combat_completed.connect(
				func(victory: bool) -> void:
					if victory:
						_on_room_completed(room, room_index)
					else:
						_on_player_defeated())
	elif room_scene is RoomPlaceholder:
		(room_scene as RoomPlaceholder).setup(room)
		room_scene.room_completed.connect(_on_room_completed.bind(room, room_index))
	else:
		# Fallback for future room scenes that follow the room_completed convention
		if room_scene.has_signal("room_completed"):
			room_scene.room_completed.connect(_on_room_completed.bind(room, room_index))

## Returns the enemy list for a room based on its type.
func _enemies_for_room(room: RoomData) -> Array[EnemyData]:
	match room.room_type:
		RoomData.RoomType.ELITE:
			if room.elite_enemy != null:
				return [room.elite_enemy]
		RoomData.RoomType.BOSS:
			if room.boss_enemy != null:
				return [room.boss_enemy]
		_:
			return room.combat_enemies
	return []

func _on_room_completed(room: RoomData, _room_index: int) -> void:
	room.cleared = true
	SaveManager.save()

	if room.room_type == RoomData.RoomType.BOSS:
		_on_floor_cleared()
		return

	_enter_map()

# ── Floor progression ──────────────────────────────────────────────────────────

func _on_floor_cleared() -> void:
	# TODO: transition to the between-floor scene (guaranteed rest + card removal),
	# then either generate the next floor or end the run.
	# For now, fall back to the map so navigation can be tested end-to-end.
	_enter_map()

func _on_player_defeated() -> void:
	# TODO: dedicated game over scene with run summary.
	SceneTransition.transition_to("res://gui/start_screen/start_screen.tscn")
