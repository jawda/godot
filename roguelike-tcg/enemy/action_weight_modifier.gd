@tool
class_name ActionWeightModifier
extends Resource

## Conditions under which this modifier's weight_bonus is applied to an action's base_weight.
## The combat system evaluates all modifiers on an action each turn and sums the active bonuses.
enum Condition {
	NONE,                      ## Always active — weight_bonus is always added
	HP_BELOW_THRESHOLD,        ## This enemy's HP is at or below threshold (0.0 – 1.0)
	HP_ABOVE_THRESHOLD,        ## This enemy's HP is at or above threshold (0.0 – 1.0)
	TOOK_DAMAGE_LAST_TURN,     ## This enemy was hit at least once during the player's last turn
	PLAYER_HP_BELOW_THRESHOLD, ## The player's HP is at or below threshold (0.0 – 1.0)
	ALLY_PRESENT,              ## At least one other enemy is alive in the current encounter
	ALLY_DIED,                 ## At least one ally has died this combat
	HAS_BLOCK,                 ## This enemy currently has block greater than zero
}

@export var condition: Condition = Condition.NONE:
	set(new_condition):
		condition = new_condition
		emit_changed()

## HP fraction used by HP_BELOW_THRESHOLD, HP_ABOVE_THRESHOLD, and PLAYER_HP_BELOW_THRESHOLD.
## e.g. 0.5 = 50% HP. Ignored by conditions that do not use a numeric threshold.
@export_range(0.0, 1.0, 0.05) var threshold: float = 0.5:
	set(new_threshold):
		threshold = new_threshold
		emit_changed()

## Amount added to the action's base_weight when this condition is active.
## Can be negative to suppress an action under certain circumstances.
## Effective weight is clamped to a minimum of 0 after all modifiers are summed.
@export var weight_bonus: int = 0:
	set(new_weight_bonus):
		weight_bonus = new_weight_bonus
		emit_changed()
