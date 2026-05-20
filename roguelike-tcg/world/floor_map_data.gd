class_name FloorMapData
extends Resource

## Runtime state for a single generated dungeon floor.
## Created by the map generator at the start of each floor and stored in
## RunSaveData so the player can quit and resume mid-floor.
##
## The room array is the authoritative source of floor layout.
## Room connections are stored on each RoomData as indices into this array.

# ── Rooms ──────────────────────────────────────────────────────────────────────

## All rooms on this floor in generation order.
## Index 0 is not guaranteed to be the start — use start_room_index.
@export var rooms: Array[RoomData] = []:
	set(new_rooms):
		rooms = new_rooms
		emit_changed()

# ── Navigation state ───────────────────────────────────────────────────────────

## Index of the room the player is currently in. -1 = floor not yet entered.
@export var current_room_index: int = -1:
	set(new_current_room_index):
		current_room_index = new_current_room_index
		emit_changed()

## Index of the START room. Set by the generator.
@export var start_room_index: int = 0:
	set(new_start_room_index):
		start_room_index = new_start_room_index
		emit_changed()

## Index of the BOSS room. Set by the generator.
@export var boss_room_index: int = 0:
	set(new_boss_room_index):
		boss_room_index = new_boss_room_index
		emit_changed()

# ── Helpers ────────────────────────────────────────────────────────────────────

## Returns the room the player is currently in, or null if not yet entered.
func get_current_room() -> RoomData:
	if current_room_index < 0 or current_room_index >= rooms.size():
		return null
	return rooms[current_room_index]

## Returns the start room.
func get_start_room() -> RoomData:
	if start_room_index < 0 or start_room_index >= rooms.size():
		return null
	return rooms[start_room_index]

## Returns the boss room.
func get_boss_room() -> RoomData:
	if boss_room_index < 0 or boss_room_index >= rooms.size():
		return null
	return rooms[boss_room_index]

## Returns rooms reachable from the current room that have not yet been visited.
## These are the valid destinations the player can choose to move to next.
func get_reachable_rooms() -> Array[RoomData]:
	var current_room: RoomData = get_current_room()
	if current_room == null:
		return []
	var reachable: Array[RoomData] = []
	for connected_index: int in current_room.connected_room_indices:
		if connected_index < 0 or connected_index >= rooms.size():
			continue
		var connected_room: RoomData = rooms[connected_index]
		if not connected_room.visited:
			reachable.append(connected_room)
	return reachable

## Returns the room at the given index, or null if out of bounds.
func get_room(room_index: int) -> RoomData:
	if room_index < 0 or room_index >= rooms.size():
		return null
	return rooms[room_index]
