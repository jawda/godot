class_name BruteBossView
extends Node3D

## Minimal preview scene for the brute boss blockout.
##   • Number keys 1-7 switch the previewed animation (idle…death).
##   • Left / Right arrows orbit the camera so you can check that the feet stay
##     planted on the floor from every yaw angle.

const ORBIT_TARGET: Vector3 = Vector3(0.0, 1.75, 0.0)
const CAMERA_RADIUS: float = 10.0
const CAMERA_HEIGHT: float = 2.25
const ORBIT_SPEED: float = 1.5

# ── Node references ──
@onready var _boss: BruteBoss = $Brute
@onready var _camera: Camera3D = $Eye
@onready var _sun: DirectionalLight3D = $Sun

# Start on the −Z side so the camera faces the boss's front (a Node3D's forward
# is −Z, which is the way the boss is built to face).
var _orbit_yaw: float = PI

func _ready() -> void:
	_sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	_update_camera()

func _process(delta: float) -> void:
	var turn_input: float = Input.get_axis(&"ui_left", &"ui_right")
	if not is_zero_approx(turn_input):
		_orbit_yaw += turn_input * ORBIT_SPEED * delta
		_update_camera()

func _update_camera() -> void:
	var orbit_offset: Vector3 = Vector3(sin(_orbit_yaw), 0.0, cos(_orbit_yaw)) * CAMERA_RADIUS
	_camera.global_position = ORBIT_TARGET + Vector3(0.0, CAMERA_HEIGHT, 0.0) + orbit_offset
	_camera.look_at(ORBIT_TARGET)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var animation_index: int = _animation_index_for_key(event.keycode)
		if animation_index >= 0 and animation_index < BruteBoss.ANIMATION_NAMES.size():
			_boss.play_animation(BruteBoss.ANIMATION_NAMES[animation_index])

func _animation_index_for_key(keycode: Key) -> int:
	match keycode:
		KEY_1: return 0
		KEY_2: return 1
		KEY_3: return 2
		KEY_4: return 3
		KEY_5: return 4
		KEY_6: return 5
		KEY_7: return 6
	return -1
