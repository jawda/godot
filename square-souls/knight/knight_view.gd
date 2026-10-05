class_name KnightView
extends Node3D

## Third-person, over-the-shoulder follow camera for the Knight.
## It stays behind the knight, swinging around to its back as it turns, so you
## always view it from behind (you can't walk "toward" the camera).
##
## Sits on the +Z side (behind the knight, which faces −Z), raised a little and
## offset to the right shoulder, at roughly shoulder height. Tune in the Inspector.

@export var look_height: float = 1.5      # height of the point the camera aims at
@export var camera_back: float = 3.0       # distance behind the character
@export var camera_up: float = 0.3         # camera raised above the look point
@export var shoulder_side: float = 0.6     # over-the-shoulder sideways offset (+ = right)
@export var follow_speed: float = 6.0      # how fast the camera swings back behind the knight

# ── Node references ──
@onready var _knight: Node3D = $Knight
@onready var _camera: Camera3D = $Eye
@onready var _sun: DirectionalLight3D = $Sun

var _orbit_yaw: float = 0.0

func _ready() -> void:
	_sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	_update_camera()

func _process(delta: float) -> void:
	# Swing the camera around to sit behind the knight's current facing, so it
	# always follows at its back (lerp_angle gives a natural trailing lag).
	_orbit_yaw = lerp_angle(_orbit_yaw, _knight.global_rotation.y, follow_speed * delta)
	_update_camera()

func _update_camera() -> void:
	var target: Vector3 = _knight.global_position + Vector3(0.0, look_height, 0.0)
	var orbit: Basis = Basis(Vector3.UP, _orbit_yaw)
	# +Z is behind the character (it faces −Z); +X is the right shoulder.
	_camera.global_position = target + orbit * Vector3(shoulder_side, camera_up, camera_back)
	# Aim slightly past the shoulder so the character sits to one side of frame.
	_camera.look_at(target + orbit * Vector3(-shoulder_side * 0.5, 0.0, 0.0))
