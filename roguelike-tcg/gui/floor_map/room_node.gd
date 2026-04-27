class_name RoomNode
extends Button

## A single room tile rendered on the floor map.
##
## Call setup() once after adding to the scene tree. The display state drives
## styling — REACHABLE rooms are interactive; all others are disabled.

# ── Display state ──────────────────────────────────────────────────────────────

enum DisplayState {
	LOCKED,    ## Not yet accessible — dimmed, non-interactive
	REACHABLE, ## Adjacent to current room, unvisited — clickable destination
	CURRENT,   ## The room the player currently occupies
	VISITED,   ## Already entered and resolved — non-interactive
}

# ── Style constants — generic rooms ────────────────────────────────────────────
## Four clearly distinct visual states:
##   LOCKED   — dim, nearly invisible; fades into background. Not reachable.
##   VISITED  — warm violet; clearly marks the path already taken.
##   REACHABLE — bright gold; interactive, "you can go here".
##   CURRENT  — bright teal; "you are here".

const FILL_LOCKED: Color    = Color(0.13, 0.12, 0.17, 1.00)  ## near-background, very dim
const FILL_REACHABLE: Color = Color(0.32, 0.25, 0.08, 1.00)
const FILL_CURRENT: Color   = Color(0.08, 0.30, 0.40, 1.00)
const FILL_VISITED: Color   = Color(0.18, 0.13, 0.28, 1.00)  ## distinct purple tint

const BORDER_LOCKED: Color    = Color(0.28, 0.26, 0.36, 1.00)  ## dim, recedes
const BORDER_REACHABLE: Color = Color(0.96, 0.80, 0.24, 1.00)
const BORDER_CURRENT: Color   = Color(0.42, 0.90, 1.00, 1.00)
const BORDER_VISITED: Color   = Color(0.62, 0.48, 0.88, 1.00)  ## bright violet, clearly "been here"
const BORDER_HOVER: Color     = Color(1.00, 0.96, 0.52, 1.00)

const FONT_LOCKED: Color    = Color(0.38, 0.36, 0.46, 1.00)  ## dim, hard to read intentionally
const FONT_REACHABLE: Color = Color(1.00, 0.93, 0.65, 1.00)
const FONT_CURRENT: Color   = Color(0.65, 0.97, 1.00, 1.00)
const FONT_VISITED: Color   = Color(0.78, 0.68, 0.95, 1.00)  ## light violet

# ── Style constants — START rooms (gold, persists across all states) ────────────

const FILL_START_REACHABLE: Color = Color(0.34, 0.26, 0.07, 1.00)
const FILL_START_CURRENT: Color   = Color(0.28, 0.22, 0.06, 1.00)
const FILL_START_VISITED: Color   = Color(0.22, 0.17, 0.05, 1.00)
const FILL_START_LOCKED: Color    = Color(0.24, 0.19, 0.06, 1.00)

const BORDER_START_REACHABLE: Color = Color(0.96, 0.80, 0.24, 1.00)
const BORDER_START_CURRENT: Color   = Color(0.84, 0.68, 0.20, 1.00)
const BORDER_START_VISITED: Color   = Color(0.62, 0.50, 0.18, 1.00)
const BORDER_START_LOCKED: Color    = Color(0.58, 0.46, 0.16, 1.00)
const BORDER_START_HOVER: Color     = Color(1.00, 0.96, 0.52, 1.00)

const FONT_START_REACHABLE: Color = Color(1.00, 0.93, 0.65, 1.00)
const FONT_START_CURRENT: Color   = Color(1.00, 0.90, 0.58, 1.00)
const FONT_START_VISITED: Color   = Color(0.88, 0.74, 0.42, 1.00)
const FONT_START_LOCKED: Color    = Color(0.82, 0.68, 0.38, 1.00)

# ── Style constants — BOSS rooms (crimson, persists across all states) ──────────

const FILL_BOSS_LOCKED: Color    = Color(0.30, 0.08, 0.08, 1.00)
const FILL_BOSS_REACHABLE: Color = Color(0.40, 0.07, 0.07, 1.00)
const FILL_BOSS_CURRENT: Color   = Color(0.36, 0.07, 0.07, 1.00)
const FILL_BOSS_VISITED: Color   = Color(0.24, 0.08, 0.08, 1.00)

const BORDER_BOSS_LOCKED: Color    = Color(0.70, 0.22, 0.22, 1.00)
const BORDER_BOSS_REACHABLE: Color = Color(0.94, 0.20, 0.20, 1.00)
const BORDER_BOSS_CURRENT: Color   = Color(0.86, 0.26, 0.26, 1.00)
const BORDER_BOSS_VISITED: Color   = Color(0.52, 0.18, 0.18, 1.00)
const BORDER_BOSS_HOVER: Color     = Color(1.00, 0.42, 0.42, 1.00)

const FONT_BOSS_LOCKED: Color    = Color(0.90, 0.54, 0.54, 1.00)
const FONT_BOSS_REACHABLE: Color = Color(1.00, 0.74, 0.74, 1.00)
const FONT_BOSS_CURRENT: Color   = Color(1.00, 0.78, 0.78, 1.00)
const FONT_BOSS_VISITED: Color   = Color(0.80, 0.50, 0.50, 1.00)

# ── Signals ─────────────────────────────────────────────────────────────────────

## Emitted when the player clicks this room. Only fires when REACHABLE.
signal room_clicked(room_index: int)

# ── Private state ───────────────────────────────────────────────────────────────

var _room_index: int = -1
var _room_type: RoomData.RoomType = RoomData.RoomType.COMBAT

# ── Public API ──────────────────────────────────────────────────────────────────

## Configure this node. Call immediately after adding to the scene tree.
## Position must be set by the caller before or after calling setup.
func setup(room: RoomData, room_index: int, display_state: DisplayState) -> void:
	_room_index = room_index
	_room_type = room.room_type
	custom_minimum_size = Vector2(room.size)
	size = Vector2(room.size)
	text = _type_text(room.room_type)
	disabled = display_state != DisplayState.REACHABLE
	_apply_style(display_state)

# ── Internals ───────────────────────────────────────────────────────────────────

func _pressed() -> void:
	room_clicked.emit(_room_index)

func _apply_style(display_state: DisplayState) -> void:
	var fill_color: Color
	var border_color: Color
	var font_color: Color
	var hover_border: Color

	match _room_type:
		RoomData.RoomType.START:
			hover_border = BORDER_START_HOVER
			match display_state:
				DisplayState.LOCKED:
					fill_color = FILL_START_LOCKED
					border_color = BORDER_START_LOCKED
					font_color = FONT_START_LOCKED
				DisplayState.REACHABLE:
					fill_color = FILL_START_REACHABLE
					border_color = BORDER_START_REACHABLE
					font_color = FONT_START_REACHABLE
				DisplayState.CURRENT:
					fill_color = FILL_START_CURRENT
					border_color = BORDER_START_CURRENT
					font_color = FONT_START_CURRENT
				_:  # VISITED
					fill_color = FILL_START_VISITED
					border_color = BORDER_START_VISITED
					font_color = FONT_START_VISITED
		RoomData.RoomType.BOSS:
			hover_border = BORDER_BOSS_HOVER
			match display_state:
				DisplayState.LOCKED:
					fill_color = FILL_BOSS_LOCKED
					border_color = BORDER_BOSS_LOCKED
					font_color = FONT_BOSS_LOCKED
				DisplayState.REACHABLE:
					fill_color = FILL_BOSS_REACHABLE
					border_color = BORDER_BOSS_REACHABLE
					font_color = FONT_BOSS_REACHABLE
				DisplayState.CURRENT:
					fill_color = FILL_BOSS_CURRENT
					border_color = BORDER_BOSS_CURRENT
					font_color = FONT_BOSS_CURRENT
				_:  # VISITED
					fill_color = FILL_BOSS_VISITED
					border_color = BORDER_BOSS_VISITED
					font_color = FONT_BOSS_VISITED
		_:  # all other room types
			hover_border = BORDER_HOVER
			match display_state:
				DisplayState.LOCKED:
					fill_color = FILL_LOCKED
					border_color = BORDER_LOCKED
					font_color = FONT_LOCKED
				DisplayState.REACHABLE:
					fill_color = FILL_REACHABLE
					border_color = BORDER_REACHABLE
					font_color = FONT_REACHABLE
				DisplayState.CURRENT:
					fill_color = FILL_CURRENT
					border_color = BORDER_CURRENT
					font_color = FONT_CURRENT
				_:  # VISITED
					fill_color = FILL_VISITED
					border_color = BORDER_VISITED
					font_color = FONT_VISITED

	var normal_style: StyleBoxFlat = _make_style(fill_color, border_color)
	var hover_style: StyleBoxFlat = _make_style(fill_color.lightened(0.12), hover_border)
	var pressed_style: StyleBoxFlat = _make_style(fill_color.darkened(0.12), hover_border)

	add_theme_stylebox_override("normal", normal_style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("disabled", normal_style)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	add_theme_color_override("font_color", font_color)
	add_theme_color_override("font_hover_color", font_color.lightened(0.2))
	add_theme_color_override("font_pressed_color", font_color)
	add_theme_color_override("font_disabled_color", font_color)
	add_theme_font_size_override("font_size", 11)

static func _make_style(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style

static func _type_text(room_type: RoomData.RoomType) -> String:
	match room_type:
		RoomData.RoomType.START:       return "START"
		RoomData.RoomType.COMBAT:      return "COMBAT"
		RoomData.RoomType.ELITE:       return "ELITE"
		RoomData.RoomType.REST:        return "REST"
		RoomData.RoomType.TREASURE:    return "CHEST"
		RoomData.RoomType.EVENT:       return "EVENT"
		RoomData.RoomType.SHOP:        return "SHOP"
		RoomData.RoomType.BLACKSMITH:  return "FORGE"
		RoomData.RoomType.BOSS:        return "BOSS"
	return "?"
