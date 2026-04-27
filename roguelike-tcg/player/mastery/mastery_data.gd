class_name MasteryData
extends Resource

## A passive class ability earned every 5 levels.
## The player chooses one from 3 options when claiming a Mastery at a rest site.
## Active masteries persist for the run and are lost on death (levels reset on death).

@export_group("Identity")

## The character class this mastery belongs to. Matches PlayerData.character_class
## (e.g. "cleric"). Leave empty for masteries available to all classes.
@export var character_class: String = "":
	set(new_character_class):
		character_class = new_character_class
		emit_changed()

@export var mastery_name: String = "":
	set(new_mastery_name):
		mastery_name = new_mastery_name
		emit_changed()

@export_multiline var description: String = "":
	set(new_description):
		description = new_description
		emit_changed()

@export_group("Effects")
@export var effects: Array[MasteryEffect] = []:
	set(new_effects):
		for existing_effect: MasteryEffect in effects:
			if existing_effect and existing_effect.changed.is_connected(_on_effect_changed):
				existing_effect.changed.disconnect(_on_effect_changed)
		effects = new_effects
		for new_effect: MasteryEffect in effects:
			if new_effect:
				new_effect.changed.connect(_on_effect_changed)
		emit_changed()

func _on_effect_changed() -> void:
	emit_changed()
