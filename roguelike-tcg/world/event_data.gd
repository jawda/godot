class_name EventData
extends Resource

## A narrative encounter presented when the player enters an Event room.
## Displays flavour text and a set of choices. Each choice has conditions
## and outcomes. The player picks one — no going back.
##
## Events are pre-assigned to EVENT rooms at map generation time, drawn
## randomly from FloorData.event_pool.

@export_group("Narrative")
@export var event_name: String = "":
	set(new_event_name):
		event_name = new_event_name
		emit_changed()

## The scene-setting text shown when the player enters the room.
## Should establish the situation and the moral weight of the choice.
@export_multiline var narrative: String = "":
	set(new_narrative):
		narrative = new_narrative
		emit_changed()

@export_group("Choices")
## The options available to the player. Typically 2–3.
## Choices with unmet conditions are shown greyed out, not hidden.
@export var choices: Array[EventChoice] = []:
	set(new_choices):
		for existing_choice: EventChoice in choices:
			if existing_choice and existing_choice.changed.is_connected(_on_choice_changed):
				existing_choice.changed.disconnect(_on_choice_changed)
		choices = new_choices
		for new_choice: EventChoice in choices:
			if new_choice:
				new_choice.changed.connect(_on_choice_changed)
		emit_changed()

func _on_choice_changed() -> void:
	emit_changed()
