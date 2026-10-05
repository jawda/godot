class_name KnightWalk
extends State

## Walk cycle: legs swing in opposite phase (knees bend on the forward reach),
## torso bobs/counter-twists, arms swing. Stride cadence is driven by actual
## velocity so it stays gripped at any speed. → Idle when stopped, → Attack.

@export var walk_cycle_speed: float = 1.3    # cadence per m/s; stride ≈ PI / this
@export var leg_swing_degrees: float = 32.0

@onready var _idle: State = $"../Idle"
@onready var _attack: State = $"../Attack"

var _knight: Knight:
	get:
		return character as Knight

var _phase: float = 0.0

func process(delta: float) -> State:
	var speed: float = Vector2(character.velocity.x, character.velocity.z).length()
	_phase += speed * walk_cycle_speed * delta
	var swing: float = sin(_phase)
	character.pose_bone(&"UpperLeg.L", Vector3(swing * leg_swing_degrees, 0.0, 0.0))
	character.pose_bone(&"UpperLeg.R", Vector3(-swing * leg_swing_degrees, 0.0, 0.0))
	character.pose_bone(&"LowerLeg.L", Vector3(-maxf(0.0, swing) * leg_swing_degrees, 0.0, 0.0))
	character.pose_bone(&"LowerLeg.R", Vector3(-maxf(0.0, -swing) * leg_swing_degrees, 0.0, 0.0))
	character.pose_bone(&"Spine1", Vector3(2.0, -swing * 4.0, 0.0))
	character.pose_bone(&"UpperArm.L", _knight.upper_arm_pose + Vector3(-swing * 6.0, 0.0, 0.0))
	character.pose_bone(&"UpperArm.R", character.mirror_arm(_knight.upper_arm_pose) + Vector3(swing * 6.0, 0.0, 0.0))
	return null

func physics(delta: float) -> State:
	var direction: Vector3 = character.movement_direction()
	if direction == Vector3.ZERO:
		return _idle
	character.velocity.x = direction.x * character.move_speed
	character.velocity.z = direction.z * character.move_speed
	character.face_direction(direction, delta)
	return null

func handle_input(event: InputEvent) -> State:
	if event.is_action_pressed(&"attack"):
		return _attack
	return null
