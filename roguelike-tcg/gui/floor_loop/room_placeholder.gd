class_name RoomPlaceholder
extends Control

## Temporary stub displayed for room types not yet implemented.
## Shows the room type name and a Continue button that returns to the map.
## Replace by routing to a real scene in FloorLoop._build_room_scene().

signal room_completed

# ── Node references ─────────────────────────────────────────────────────────────

@onready var _room_title: Label = $Panel/Contents/RoomTitle
@onready var _continue_button: Button = $Panel/Contents/Continue

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)

# ── Public API ─────────────────────────────────────────────────────────────────

func setup(room: RoomData) -> void:
	_room_title.text = _type_display_name(room.room_type)

# ── Private ────────────────────────────────────────────────────────────────────

func _on_continue_pressed() -> void:
	room_completed.emit()

static func _type_display_name(room_type: RoomData.RoomType) -> String:
	match room_type:
		RoomData.RoomType.COMBAT:     return "Combat"
		RoomData.RoomType.ELITE:      return "Elite"
		RoomData.RoomType.REST:       return "Rest"
		RoomData.RoomType.TREASURE:   return "Treasure"
		RoomData.RoomType.EVENT:      return "Event"
		RoomData.RoomType.SHOP:       return "Shop"
		RoomData.RoomType.BLACKSMITH: return "Blacksmith"
		RoomData.RoomType.BOSS:       return "Boss"
	return "Unknown"
