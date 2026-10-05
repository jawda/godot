class_name KnightIdle
extends State

## Layered idle: breathing + a slow weight shift, on offset sine waves so it
## doesn't look robotic. → Walk when moving, → Attack on the attack input.

@export var breathe_degrees: float = 3.0
@export var breathe_speed: float = 1.5

const SWAY_SPEED: float = 0.55   # weight-shift cycle, slower than the breath

@onready var _walk: State = $"../Walk"
@onready var _attack: State = $"../Attack"

var _knight: Knight:
	get:
		return character as Knight

var _elapsed: float = 0.0

func process(delta: float) -> State:
	_elapsed += delta
	var breathe: float = sin(_elapsed * breathe_speed)
	var sway: float = sin(_elapsed * SWAY_SPEED)
	character.pose_bone(&"Spine1", Vector3(breathe * breathe_degrees, sway * 1.5, 0.0))
	character.pose_bone(&"Spine2", Vector3(breathe * breathe_degrees * 0.4, 0.0, 0.0))
	character.pose_bone(&"Head", Vector3(-breathe * 1.5, sway * 2.5, 0.0))
	var arm_drift: float = breathe * 2.0
	character.pose_bone(&"UpperArm.L", _knight.upper_arm_pose + Vector3(arm_drift, 0.0, 0.0))
	character.pose_bone(&"UpperArm.R", character.mirror_arm(_knight.upper_arm_pose) + Vector3(arm_drift, 0.0, 0.0))
	return null

func physics(_delta: float) -> State:
	if character.movement_direction() != Vector3.ZERO:
		return _walk
	character.velocity.x = 0.0
	character.velocity.z = 0.0
	return null

func handle_input(event: InputEvent) -> State:
	if event.is_action_pressed(&"attack"):
		return _attack
	return null
