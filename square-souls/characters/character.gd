@tool
class_name Character
extends CharacterBody3D

## Reusable base for player characters (Knight, Mage, …). Holds the shared
## context the states operate on: model fitting/grounding, a skeleton-posing API,
## camera-relative movement, gravity, held-item follow, and the state machine.
##
## Subclasses fill in the virtual hooks: _configure() (cache bones/items),
## _apply_base_pose() (the resting pose shown in the editor), and
## _update_held_items() (place weapons/props on the hands each frame).
##
## @tool so the model fits, poses and holds items live in the editor; the state
## machine only runs at runtime, so animation never plays in the editor.

@export var target_height: float = 1.8:
	set(value):
		target_height = value
		if is_inside_tree():
			_fit_model()
@export var feet_offset: float = 0.0:
	set(value):
		feet_offset = value
		if is_inside_tree():
			_fit_model()
@export var move_speed: float = 6.5      # metres / second
@export var turn_speed: float = 10.0     # how fast the character turns to face movement

# ── Node references ──
@onready var _model: Node3D = $Model
@onready var _bounds: CollisionShape3D = $Bounds
@onready var _state_machine: CharacterStateMachine = $StateMachine

var skeleton: Skeleton3D = null
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))

func _ready() -> void:
	_fit_model()
	skeleton = _find_skeleton()
	_configure()
	_apply_base_pose()
	if not Engine.is_editor_hint() and _state_machine != null:
		_state_machine.initialize(self)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# States set the horizontal velocity in their physics(); we apply gravity and slide.
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()

func _process(_delta: float) -> void:
	# Held items follow the hands in the editor too (for lining up grips); the
	# state machine handles animation at runtime.
	_update_held_items()

# ── Virtual hooks (subclasses override) ───────────────────────────────────────

## Cache subclass-specific bones/items after the skeleton is found.
func _configure() -> void:
	pass

## The resting pose shown in the editor (states drive it at runtime).
func _apply_base_pose() -> void:
	pass

## Place held props (weapons/shields) on their bones. Runs every frame.
func _update_held_items() -> void:
	pass

# ── Skeleton posing API (used by states) ──────────────────────────────────────

## Resets every bone to its rest rotation. Called each frame before the active
## state poses the bones it animates, so nothing stays stuck between states.
func reset_pose() -> void:
	if skeleton == null:
		return
	for bone_index: int in skeleton.get_bone_count():
		skeleton.set_bone_pose_rotation(bone_index, skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion())

## Rotates a named bone by an euler-degrees delta from its rest pose.
func pose_bone(bone_name: StringName, euler_degrees: Vector3) -> void:
	if skeleton == null:
		return
	set_bone_rotation(skeleton.find_bone(bone_name), euler_degrees)

## Rotates a bone (by index) by an euler-degrees delta from its rest pose.
func set_bone_rotation(bone_index: int, euler_degrees: Vector3) -> void:
	if skeleton == null or bone_index == -1:
		return
	var rest_rotation: Quaternion = skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion()
	var delta: Quaternion = Quaternion.from_euler(Vector3(deg_to_rad(euler_degrees.x), deg_to_rad(euler_degrees.y), deg_to_rad(euler_degrees.z)))
	skeleton.set_bone_pose_rotation(bone_index, rest_rotation * delta)

## Mirrors a left-side pose to the right side (flip the sideways/roll components).
func mirror_arm(pose: Vector3) -> Vector3:
	return Vector3(pose.x, -pose.y, -pose.z)

## First matching bone index from a list of candidate names (names can vary).
func find_bone_index(candidate_names: Array) -> int:
	if skeleton == null:
		return -1
	for candidate: StringName in candidate_names:
		var index: int = skeleton.find_bone(candidate)
		if index != -1:
			return index
	return -1

# ── Movement helpers (used by states) ─────────────────────────────────────────

## WASD input projected onto the ground, relative to the camera's facing.
func movement_direction() -> Vector3:
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_back", &"move_forward")
	if input == Vector2.ZERO:
		return Vector3.ZERO
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return Vector3(input.x, 0.0, -input.y).normalized()
	var camera_basis: Basis = camera.global_transform.basis
	var forward: Vector3 = -camera_basis.z
	var right: Vector3 = camera_basis.x
	forward.y = 0.0
	right.y = 0.0
	return (right.normalized() * input.x + forward.normalized() * input.y).normalized()

## Smoothly turns to face a movement direction (the character's forward is −Z).
func face_direction(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	var target_yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

## Seats a held item on a hand bone: bone position + rotation (skeleton scale
## stripped) plus a local grip offset/rotation/scale.
func place_item(item: Node3D, bone_index: int, offset: Vector3, euler_degrees: Vector3, item_scale: float) -> void:
	if item == null or skeleton == null or bone_index == -1:
		return
	var hand: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone_index)
	var hand_basis: Basis = hand.basis.orthonormalized()
	var grip_rotation: Basis = Basis.from_euler(Vector3(deg_to_rad(euler_degrees.x), deg_to_rad(euler_degrees.y), deg_to_rad(euler_degrees.z)))
	var grip_basis: Basis = hand_basis * grip_rotation * Basis.from_scale(Vector3.ONE * item_scale)
	item.global_transform = Transform3D(grip_basis, hand.origin + hand_basis * offset)

# ── Model fitting (scale / recentre / ground) ─────────────────────────────────

func _fit_model() -> void:
	if _model == null:
		return
	_model.transform = Transform3D.IDENTITY
	var rest_bounds: AABB = _bone_bounds()
	if rest_bounds.size.y <= 0.0:
		return
	var scale_factor: float = target_height / rest_bounds.size.y
	var fitted_basis: Basis = Basis(Vector3.UP, PI) * Basis.from_scale(Vector3.ONE * scale_factor)
	_model.transform = Transform3D(fitted_basis, Vector3.ZERO)
	var placed_bounds: AABB = _bone_bounds()
	_model.position = Vector3(-placed_bounds.get_center().x, -placed_bounds.position.y + feet_offset, -placed_bounds.get_center().z)
	_fit_collision()

func _fit_collision() -> void:
	if _bounds == null:
		return
	var capsule: CapsuleShape3D = _bounds.shape as CapsuleShape3D
	if capsule == null:
		return
	capsule.radius = minf(capsule.radius, target_height * 0.25)
	capsule.height = target_height
	_bounds.position = Vector3(0.0, target_height * 0.5, 0.0)

## Bounding box of the skeleton's bone positions, in this body's space.
func _bone_bounds() -> AABB:
	var found_skeleton: Skeleton3D = _find_skeleton()
	if found_skeleton == null:
		return AABB()
	var body_inverse: Transform3D = global_transform.affine_inverse()
	var merged: AABB = AABB()
	var found: bool = false
	for bone_index: int in found_skeleton.get_bone_count():
		var bone_position: Vector3 = body_inverse * (found_skeleton.global_transform * found_skeleton.get_bone_global_pose(bone_index)).origin
		if not found:
			merged = AABB(bone_position, Vector3.ZERO)
			found = true
		else:
			merged = merged.expand(bone_position)
	return merged if found else AABB()

func _find_skeleton() -> Skeleton3D:
	if _model == null:
		return null
	var skeletons: Array[Node] = _model.find_children("*", "Skeleton3D", true, false)
	return skeletons[0] as Skeleton3D if not skeletons.is_empty() else null
