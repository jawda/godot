class_name EventChoice
extends Resource

## A single selectable option in an EventData.
## Displays as a button during the event. Conditions gate availability.
## Outcomes fire in order when the choice is made.

@export_group("Display")
## The text shown on the choice button.
@export var label: String = "":
	set(new_label):
		label = new_label
		emit_changed()

## Flavour text shown after the player commits to this choice, before outcomes resolve.
## Use this to narrate what happens as a result of the decision.
@export_multiline var result_text: String = "":
	set(new_result_text):
		result_text = new_result_text
		emit_changed()

@export_group("Conditions")
## All conditions must be met for this choice to be available.
## Unavailable choices are shown greyed out with a hint, not hidden entirely.

## Minimum gold the player must currently hold. 0 = no requirement.
@export var required_gold: int = 0:
	set(new_required_gold):
		required_gold = new_required_gold
		emit_changed()

## Minimum HP the player must currently have. 0 = no requirement.
## Set this above the HP cost of the choice so the player cannot kill themselves.
@export var required_hp: int = 0:
	set(new_required_hp):
		required_hp = new_required_hp
		emit_changed()

## Restricts this choice to a specific character class. Empty = available to all.
## Matches PlayerData.character_class (e.g. "cleric").
@export var required_class: String = "":
	set(new_required_class):
		required_class = new_required_class
		emit_changed()

@export_group("Outcomes")
## Effects applied in order when this choice is confirmed.
@export var outcomes: Array[EventOutcome] = []:
	set(new_outcomes):
		for existing_outcome: EventOutcome in outcomes:
			if existing_outcome and existing_outcome.changed.is_connected(_on_outcome_changed):
				existing_outcome.changed.disconnect(_on_outcome_changed)
		outcomes = new_outcomes
		for new_outcome: EventOutcome in outcomes:
			if new_outcome:
				new_outcome.changed.connect(_on_outcome_changed)
		emit_changed()

func _on_outcome_changed() -> void:
	emit_changed()

## Returns true if all conditions are satisfied for the given player state.
func is_available(current_gold: int, current_hp: int, player_class: String) -> bool:
	if required_gold > 0 and current_gold < required_gold:
		return false
	if required_hp > 0 and current_hp < required_hp:
		return false
	if not required_class.is_empty() and player_class != required_class:
		return false
	return true
