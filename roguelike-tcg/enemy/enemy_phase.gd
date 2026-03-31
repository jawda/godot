@tool
class_name EnemyPhase
extends Resource

## HP percentage (0.0 – 1.0) at which this phase activates.
## Triggers when the enemy's current HP drops to or below this fraction of max HP.
## e.g. 0.5 triggers at 50% HP or below.
## Phases in EnemyData.phases should be sorted threshold-descending so the
## highest applicable threshold is always checked first.
@export var hp_threshold: float = 0.5:
	set(new_hp_threshold):
		hp_threshold = clampf(new_hp_threshold, 0.0, 1.0)
		emit_changed()

## Replaces the enemy's current action pool when this phase activates.
## The enemy resets its action index and begins cycling this pool from the start.
@export var actions: Array[EnemyAction] = []:
	set(new_actions):
		actions = new_actions
		emit_changed()

## Optional flavour shown to the player when this phase triggers.
## Leave empty for a silent phase transition.
## e.g. "The necromancer's eyes go dark. Something ancient stirs within him."
@export_multiline var on_trigger_description: String = "":
	set(new_on_trigger_description):
		on_trigger_description = new_on_trigger_description
		emit_changed()
