class_name KnightAttack
extends State

## The full sword slash, driven by one windup→apex→strike→recover timeline:
## raise + cock the elbow + step the feet, roll the wrist at the apex, then swing
## down/across while the elbow snaps straight and the body twists — the shield
## tucking and turning to guard, the hips leaning while the torso stays upright.
## Movement is locked during the swing; returns to Idle/Walk when it finishes.

@export var attack_duration: float = 0.55                     # seconds for the whole swing
@export var attack_windup: Vector3 = Vector3(0, 0, -140)      # sword arm raises up to the side (Z)
@export var attack_strike: Vector3 = Vector3(0, 10, 35)       # sword arm arcs down (Z); body twist carries it across
@export var attack_wrist: Vector3 = Vector3(-90, 90, 0)       # wrist turn at the apex to angle the blade for a slice
@export var attack_forearm: Vector3 = Vector3(90, 0, 0)       # sword elbow cocks at the apex, snaps straight on the strike
@export var attack_shield_bend: Vector3 = Vector3(90, 0, 0)   # shield elbow bends on the windup, then returns
@export var attack_shield_wrist: Vector3 = Vector3(0, 0, -90) # shield hand turns to guard, then returns
@export var attack_left_hip: Vector3 = Vector3(0, 0, 0)       # left leg during the windup
@export var attack_left_knee: Vector3 = Vector3(40, 0, 0)     # left knee bends during the windup
@export var attack_right_hip: Vector3 = Vector3(-30, 0, 0)    # right leg steps back during the windup
@export var attack_right_knee: Vector3 = Vector3(-40, 0, 0)   # right knee bends during the windup
@export var attack_right_foot: Vector3 = Vector3(0, 0, -90)   # right foot pivots on the plant
@export var attack_hip_twist: float = 0.6                     # hips rotate this fraction of the body twist
@export var attack_hip_tilt: Vector3 = Vector3(0, 0, 15)      # waist drops the right side on the windup
@export var attack_spine_counter: float = 1.0                 # spine counters the hip tilt so the torso stays upright
@export var attack_leg_plant: float = 1.0                     # legs counter the hip rotation to stay planted

@onready var _idle: State = $"../Idle"
@onready var _walk: State = $"../Walk"

var _knight: Knight:
	get:
		return character as Knight

var _elapsed: float = 0.0

func enter() -> void:
	_elapsed = 0.0

func process(delta: float) -> State:
	_elapsed += delta
	_animate(clampf(_elapsed / attack_duration, 0.0, 1.0))
	if _elapsed >= attack_duration:
		return _walk if character.movement_direction() != Vector3.ZERO else _idle
	return null

func physics(_delta: float) -> State:
	# Planted while swinging.
	character.velocity.x = 0.0
	character.velocity.z = 0.0
	return null

## Poses the whole body for the swing at normalized time t (0→1).
func _animate(t: float) -> void:
	var amount: float = _windup_amount(t)
	# Shield arm: elbow tucks and hand turns to guard on the windup, then returns.
	character.pose_bone(&"UpperArm.L", _knight.upper_arm_pose)
	character.pose_bone(&"LowerArm.L", attack_shield_bend * amount)
	character.set_bone_rotation(_knight.left_hand, attack_shield_wrist * amount)
	# Sword arm: swing + apex wrist roll + elbow cock-and-snap.
	character.pose_bone(&"UpperArm.R", character.mirror_arm(_knight.upper_arm_pose) + _swing(t))
	character.set_bone_rotation(_knight.right_hand, attack_wrist * _wrist_amount(t))
	character.pose_bone(&"LowerArm.R", attack_forearm * amount)
	# Waist tilts + twists; legs counter it to stay planted; right foot pivots.
	var hip_pose: Vector3 = attack_hip_tilt * amount + Vector3(0.0, _twist(t) * attack_hip_twist, 0.0)
	character.pose_bone(&"Root", hip_pose)
	character.pose_bone(&"UpperLeg.L", attack_left_hip * amount - hip_pose * attack_leg_plant)
	character.pose_bone(&"LowerLeg.L", attack_left_knee * amount)
	character.pose_bone(&"UpperLeg.R", attack_right_hip * amount - hip_pose * attack_leg_plant)
	character.pose_bone(&"LowerLeg.R", attack_right_knee * amount)
	character.pose_bone(&"Fot.R", attack_right_foot * amount)
	# Spine twists with the body but counters the hip tilt so the torso stays upright.
	character.pose_bone(&"Spine1", Vector3(0.0, _twist(t), 0.0) - attack_hip_tilt * attack_spine_counter * amount)

# ── Timing curves (all keyed off the one normalized t) ────────────────────────

## Bend/step curve: peaks at the apex on the windup, returns through the strike.
func _windup_amount(t: float) -> float:
	if t < 0.4:
		return t / 0.4
	elif t < 0.6:
		return 1.0 - (t - 0.4) / 0.2
	return 0.0

## Wrist-turn curve: neutral through the raise, snaps at the apex, holds through
## the strike, then eases out.
func _wrist_amount(t: float) -> float:
	if t < 0.35:
		return 0.0
	elif t < 0.45:
		return (t - 0.35) / 0.1
	elif t < 0.75:
		return 1.0
	return 1.0 - (t - 0.75) / 0.25

## Sword-arm euler through the swing: ease out into the windup, snap into the
## strike, ease back on recovery.
func _swing(t: float) -> Vector3:
	var windup_end: float = 0.4
	var strike_end: float = 0.6
	if t < windup_end:
		var windup_k: float = t / windup_end
		return Vector3.ZERO.lerp(attack_windup, 1.0 - (1.0 - windup_k) * (1.0 - windup_k))
	if t < strike_end:
		var strike_k: float = (t - windup_end) / (strike_end - windup_end)
		return attack_windup.lerp(attack_strike, strike_k * strike_k)
	var recover_k: float = (t - strike_end) / (1.0 - strike_end)
	return attack_strike.lerp(Vector3.ZERO, recover_k)

## Body twist (spine Y): winds back on the windup, swings hard through the strike.
func _twist(t: float) -> float:
	if t < 0.4:
		return lerpf(0.0, -30.0, t / 0.4)
	elif t < 0.6:
		return lerpf(-30.0, 50.0, (t - 0.4) / 0.2)
	return lerpf(50.0, 0.0, (t - 0.6) / 0.4)
