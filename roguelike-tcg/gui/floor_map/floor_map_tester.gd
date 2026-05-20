class_name FloorMapTester
extends Control

## Standalone test scene for the floor map.
## Generates a floor map from floor_01_the_crypt.tres and renders it.
## Press Regenerate to produce a new random layout — each run of the BSP
## generator is seeded differently so layouts vary.

const FLOOR_DATA: FloorData = preload("res://world/data/floor_01_the_crypt.tres")

# ── Node references ─────────────────────────────────────────────────────────────

@onready var _floor_map: FloorMap = $FloorMap
@onready var _room_info: Label = $TestControls/Contents/RoomInfo

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_generate()

# ── Private ────────────────────────────────────────────────────────────────────

func _generate() -> void:
	var floor_map_data: FloorMapData = FloorMapGenerator.generate(FLOOR_DATA)
	_floor_map.refresh(floor_map_data, "Floor 1 — The Crypt")
	_room_info.text = "%d rooms generated" % floor_map_data.rooms.size()

# ── Signals ────────────────────────────────────────────────────────────────────

func _on_regenerate_pressed() -> void:
	_generate()
