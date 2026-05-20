class_name FloorData
extends Resource

## Static configuration for a single floor of the dungeon.
## The map generator reads this to know which rooms to place, how many,
## which enemies can spawn, and who the boss is.
##
## One FloorData resource per floor. A run is an ordered Array[FloorData]
## defined in the run configuration — add or remove floors freely.

@export_group("Identity")
@export var floor_name: String = "":
	set(new_floor_name):
		floor_name = new_floor_name
		emit_changed()

@export_multiline var description: String = "":
	set(new_description):
		description = new_description
		emit_changed()

@export var floor_number: int = 1:
	set(new_floor_number):
		floor_number = new_floor_number
		emit_changed()

@export_group("Room Generation")
## Minimum number of non-boss rooms on this floor (excluding Start and Boss).
@export var min_rooms: int = 8:
	set(new_min_rooms):
		min_rooms = new_min_rooms
		emit_changed()

## Maximum number of non-boss rooms on this floor (excluding Start and Boss).
@export var max_rooms: int = 12:
	set(new_max_rooms):
		max_rooms = new_max_rooms
		emit_changed()

## Whether a Blacksmith room can appear on this floor.
## Disable on floor 1 — players have no gear to upgrade yet.
@export var allow_blacksmith: bool = false:
	set(new_allow_blacksmith):
		allow_blacksmith = new_allow_blacksmith
		emit_changed()

@export_group("Room Weights")
## Relative weights for each room type. Do not need to sum to any specific value —
## the map generator normalises them. Set a weight to 0 to exclude that type entirely.
@export var combat_weight: int = 25:
	set(new_combat_weight):
		combat_weight = new_combat_weight
		emit_changed()

@export var elite_weight: int = 8:
	set(new_elite_weight):
		elite_weight = new_elite_weight
		emit_changed()

@export var rest_weight: int = 14:
	set(new_rest_weight):
		rest_weight = new_rest_weight
		emit_changed()

@export var treasure_weight: int = 12:
	set(new_treasure_weight):
		treasure_weight = new_treasure_weight
		emit_changed()

@export var event_weight: int = 14:
	set(new_event_weight):
		event_weight = new_event_weight
		emit_changed()

@export var shop_weight: int = 10:
	set(new_shop_weight):
		shop_weight = new_shop_weight
		emit_changed()

## Only used if allow_blacksmith is true.
@export var blacksmith_weight: int = 4:
	set(new_blacksmith_weight):
		blacksmith_weight = new_blacksmith_weight
		emit_changed()

@export_group("Enemies")
## Events that can appear in event rooms on this floor.
## The generator picks one randomly per event room.
@export var event_pool: Array[EventData] = []:
	set(new_event_pool):
		event_pool = new_event_pool
		emit_changed()

## Enemies that can appear in standard combat rooms on this floor.
## The generator picks 1–3 randomly per room.
@export var combat_enemies: Array[EnemyData] = []:
	set(new_combat_enemies):
		combat_enemies = new_combat_enemies
		emit_changed()

## Enemies that can appear in elite rooms on this floor.
## The generator picks one per elite room.
@export var elite_enemies: Array[EnemyData] = []:
	set(new_elite_enemies):
		elite_enemies = new_elite_enemies
		emit_changed()

## Possible bosses for this floor. One is chosen randomly at map generation time.
## Having multiple entries means each run may face a different floor boss.
@export var boss_pool: Array[EnemyData] = []:
	set(new_boss_pool):
		boss_pool = new_boss_pool
		emit_changed()
