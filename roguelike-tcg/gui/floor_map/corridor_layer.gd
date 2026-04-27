class_name CorridorLayer
extends Node2D

## Draws curved corridor lines between connected room centres on the floor map.
##
## Each corridor is a cubic bezier — control points extend horizontally from
## each endpoint so the curves bow naturally left-to-right between columns.

# ── Style ──────────────────────────────────────────────────────────────────────

const CORRIDOR_COLOR: Color = Color(0.38, 0.35, 0.45, 0.55)
const CORRIDOR_WIDTH: float = 3.0

## Number of line segments used to approximate each bezier. Higher = smoother.
const BEZIER_STEPS: int = 40

# ── State ──────────────────────────────────────────────────────────────────────

var _corridor_pairs: Array = []

# ── Public API ─────────────────────────────────────────────────────────────────

func set_corridors(pairs: Array) -> void:
	_corridor_pairs = pairs
	queue_redraw()

# ── Drawing ────────────────────────────────────────────────────────────────────

func _draw() -> void:
	for pair: Array in _corridor_pairs:
		var from_point: Vector2 = pair[0] as Vector2
		var to_point: Vector2 = pair[1] as Vector2
		draw_polyline(_sample_bezier(from_point, to_point), CORRIDOR_COLOR, CORRIDOR_WIDTH, true)

## Sample BEZIER_STEPS+1 points along a cubic bezier between two room centres.
## Tension scales with vertical distance so same-height rooms get a gentle arc
## while rooms far apart vertically get a dramatic S-curve. The 30 % y-lean
## fans multiple connections from the same source apart in the crossing zone.
static func _sample_bezier(from_point: Vector2, to_point: Vector2) -> PackedVector2Array:
	var horiz: float = absf(to_point.x - from_point.x)
	var vert: float  = absf(to_point.y - from_point.y)
	# Tension proportional to vertical separation, capped at horiz so control
	# points never overshoot their column and create backward loops.
	var tension: float = clampf(vert / horiz, 0.15, 1.0) * horiz
	var control_a: Vector2 = Vector2(from_point.x + tension, lerpf(from_point.y, to_point.y, 0.3))
	var control_b: Vector2 = Vector2(to_point.x  - tension, lerpf(to_point.y, from_point.y, 0.3))

	var points: PackedVector2Array = PackedVector2Array()
	for step: int in BEZIER_STEPS + 1:
		var t: float = float(step) / float(BEZIER_STEPS)
		points.append(from_point.bezier_interpolate(control_a, control_b, to_point, t))
	return points
