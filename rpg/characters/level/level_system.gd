class_name LevelSystem
extends Node

## Tracks character level, XP, and unspent skill points.
## Attach as a sibling to CharacterStats on any character node.

signal leveled_up(new_level: int, points_gained: int)
signal xp_changed(current_xp: int, xp_required: int)

## Skill points awarded each level up.
@export var skill_points_per_level: int = 3

## Scaling constants for the XP curve.
## Required XP = floor(xp_base * level ^ xp_exponent)
## Default gives roughly: L1->2: 100, L5->6: 1118, L10->11: 3162
@export var xp_base: float = 100.0
@export var xp_exponent: float = 1.5

var current_level: int = 1
var current_xp: int = 0
var skill_points: int = 0


func xp_required() -> int:
	return int(xp_base * pow(current_level, xp_exponent))


func add_xp(amount: int) -> void:
	current_xp += amount
	xp_changed.emit(current_xp, xp_required())
	_check_level_up()


func _check_level_up() -> void:
	while current_xp >= xp_required():
		current_xp -= xp_required()
		current_level += 1
		skill_points += skill_points_per_level
		leveled_up.emit(current_level, skill_points_per_level)
		xp_changed.emit(current_xp, xp_required())


## Returns true and deducts a point if one is available.
func spend_skill_point() -> bool:
	if skill_points <= 0:
		return false
	skill_points -= 1
	return true


func refund_skill_point() -> void:
	skill_points += 1


func has_unspent_points() -> bool:
	return skill_points > 0
