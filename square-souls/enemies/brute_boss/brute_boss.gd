class_name BruteBoss
extends CharacterBody3D

## Blockout of the brute boss enemy — a grey-box character built from Godot
## primitive meshes on a Node3D joint hierarchy, driven by an AnimationPlayer.
##
## This pass assembles the rig, colliders and hitboxes and can play any of the
## seven animation clips. The full state machine, frame-accurate hitbox windows
## and damage handling described in the handoff README are a later pass.

## The seven animation names. Also used by the view scene to map number keys 1-7
## to a preview animation. Clips live in the AnimationPlayer inside brute_boss.tscn
## (the "idle" clip autoplays); edit them in the editor's Animation panel.
const ANIMATION_NAMES: Array[StringName] = [
	&"idle", &"walk", &"slam", &"sweep", &"hurt", &"roar", &"death",
]

@export var stats: BruteBossStats

## The slam raises the weapon overhead, holds for a random time in this range
## (a variable telegraph the player can't perfectly time), then strikes.
@export var slam_hold_min: float = 0.4
@export var slam_hold_max: float = 4.0

## Colour the arms flash to as the "here it comes" tell before a slam strike.
const FLASH_COLOR: Color = Color(0.9, 0.15, 0.12)

# ── Node references ──
@onready var _animator: AnimationPlayer = $Animator
@onready var _arm_material: StandardMaterial3D = $Figure/Pelvis/Spine/ArmRig/LeftArm/UpperArm.material_override
@onready var _arm_base_color: Color = _arm_material.albedo_color if _arm_material != null else Color(0.42, 0.46, 0.55)
@onready var _bounds: CollisionShape3D = $Bounds
@onready var _hurtbox: Area3D = $Hurtbox
@onready var _slam_hitbox: Area3D = $SlamHitbox
@onready var _sweep_hitbox: Area3D = $SweepHitbox
@onready var _aggro_range: Area3D = $AggroRange
@onready var _attack_range: Area3D = $AttackRange
@onready var _audio: AudioStreamPlayer3D = $Audio

var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()

var _slam_active: bool = false

## Plays one of the seven animations by name. The "slam" is a sequenced attack
## (windup → variable hold → strike) rather than a single clip.
func play_animation(animation_name: StringName) -> void:
	if animation_name == &"slam":
		_perform_slam()
		return
	if not _animator.has_animation(animation_name):
		push_warning("BruteBoss: no animation named '%s'." % animation_name)
		return
	_animator.play(animation_name)

## Raise overhead, hold for a random telegraph, then strike. Runs as a coroutine.
func _perform_slam() -> void:
	if _slam_active:
		return
	if not (_animator.has_animation(&"slam_windup") and _animator.has_animation(&"slam_strike")):
		push_warning("BruteBoss: slam clips missing.")
		return
	_slam_active = true
	_animator.play(&"slam_windup")
	await _animator.animation_finished
	var hold_time: float = randf_range(slam_hold_min, slam_hold_max)
	await get_tree().create_timer(hold_time).timeout
	await _flash_arms()
	_animator.play(&"slam_strike")
	await _animator.animation_finished
	_slam_active = false

## Pulses the arms red and back — the telegraph right before the strike lands.
func _flash_arms() -> void:
	if _arm_material == null:
		return
	var flash: Tween = create_tween()
	flash.tween_property(_arm_material, "albedo_color", FLASH_COLOR, 0.12)
	flash.tween_property(_arm_material, "albedo_color", _arm_base_color, 0.12)
	await flash.finished
