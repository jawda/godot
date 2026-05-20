class_name Cup
extends Control

## A hand-drawn goblet/chalice for the shell game.
## Set is_clickable = true to enable hover highlight and click signal.

signal cup_clicked(cup_index: int)

var cup_index: int = 0
var is_clickable: bool = false : set = _set_clickable

const _COLOR_FILL: Color   = Color(0.22, 0.16, 0.30, 1.0)
const _COLOR_HOVER: Color  = Color(0.36, 0.26, 0.50, 1.0)
const _COLOR_BORDER: Color = Color(0.78, 0.60, 0.20, 1.0)

var _hovered: bool = false

func _set_clickable(value: bool) -> void:
	is_clickable = value
	mouse_filter = MOUSE_FILTER_STOP if value else MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var fill: Color = _COLOR_HOVER if (_hovered and is_clickable) else _COLOR_FILL

	# Full goblet outline as a single polygon (clockwise from top-left):
	# wide opening → tapered body → narrow stem → wide base
	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(w * 0.06, 0.0),       # top-left of rim
		Vector2(w * 0.94, 0.0),       # top-right of rim
		Vector2(w * 0.72, h * 0.58),  # bottom-right of cup body
		Vector2(w * 0.57, h * 0.58),  # right of stem top
		Vector2(w * 0.57, h * 0.82),  # right of stem bottom
		Vector2(w * 0.92, h * 0.82),  # right of base top
		Vector2(w * 0.96, h),         # bottom-right corner
		Vector2(w * 0.04, h),         # bottom-left corner
		Vector2(w * 0.08, h * 0.82),  # left of base top
		Vector2(w * 0.43, h * 0.82),  # left of stem bottom
		Vector2(w * 0.43, h * 0.58),  # left of stem top
		Vector2(w * 0.28, h * 0.58),  # bottom-left of cup body
	])

	draw_colored_polygon(outline, fill)

	var border: PackedVector2Array = outline.duplicate()
	border.append(outline[0])
	draw_polyline(border, _COLOR_BORDER, 1.5, false)

	# Rim highlight — a subtle lighter line across the opening
	draw_line(
		Vector2(w * 0.06, 1.0),
		Vector2(w * 0.94, 1.0),
		Color(_COLOR_BORDER.r, _COLOR_BORDER.g, _COLOR_BORDER.b, 0.50),
		2.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovered = true
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovered = false
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not is_clickable:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			cup_clicked.emit(cup_index)
