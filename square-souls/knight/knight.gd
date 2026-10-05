@tool
class_name Knight
extends Character

## Knight-specific configuration on top of the generic Character. The moveset
## (idle / walk / attack) lives in the state nodes under the StateMachine; this
## just supplies the arms-down base pose, the sword/shield grips, and the hand
## bones the states/items use.

## Euler-degrees rotation that brings the left arm down from the T-pose (the
## right mirrors). The shared resting pose all the knight's states build on.
@export var upper_arm_pose: Vector3 = Vector3(0, 0, -75):
	set(value):
		upper_arm_pose = value
		if is_inside_tree():
			_apply_base_pose()

## Grip offsets for the held items — tune live in the editor to seat them.
@export_group("Sword (right hand)")
@export var sword_offset: Vector3 = Vector3.ZERO:
	set(value):
		sword_offset = value
		_refresh_items()
@export var sword_rotation: Vector3 = Vector3.ZERO:
	set(value):
		sword_rotation = value
		_refresh_items()
@export var sword_scale: float = 0.5:
	set(value):
		sword_scale = value
		_refresh_items()
@export_group("Shield (left hand)")
@export var shield_offset: Vector3 = Vector3.ZERO:
	set(value):
		shield_offset = value
		_refresh_items()
@export var shield_rotation: Vector3 = Vector3.ZERO:
	set(value):
		shield_rotation = value
		_refresh_items()
@export var shield_scale: float = 0.5:
	set(value):
		shield_scale = value
		_refresh_items()
@export_group("")

# ── Node references ──
@onready var _sword: Node3D = $Sword
@onready var _shield: Node3D = $Shield

# Cached hand bones (name varies between rigs; resolved with fallbacks). Public
# so the attack state can pose the wrists.
var right_hand: int = -1
var left_hand: int = -1

## Cache the hand bones once the skeleton is found (called by Character._ready).
func _configure() -> void:
	right_hand = find_bone_index([&"Hand.R", &"Hand_R"])
	left_hand = find_bone_index([&"Hand.L", &"Hand_L"])

## The resting pose shown in the editor (arms down); states drive it at runtime.
func _apply_base_pose() -> void:
	if skeleton == null:
		return
	pose_bone(&"UpperArm.L", upper_arm_pose)
	pose_bone(&"UpperArm.R", mirror_arm(upper_arm_pose))

## Seats the sword on the right hand and the shield on the left, every frame.
func _update_held_items() -> void:
	place_item(_sword, right_hand, sword_offset, sword_rotation, sword_scale)
	place_item(_shield, left_hand, shield_offset, shield_rotation, shield_scale)

func _refresh_items() -> void:
	if is_inside_tree():
		_update_held_items()
