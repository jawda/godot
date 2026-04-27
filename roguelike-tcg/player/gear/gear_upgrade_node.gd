@tool
class_name GearUpgradeNode
extends Resource

## A single node in a gear item's upgrade tree.
##
## Every blacksmith upgrade presents a choice between an item's available next_options.
## When this node is active, its effects and description replace the base item entirely.
## A node with no next_options is a dead end — the item cannot be upgraded further along
## this path. A node with one next_option upgrades linearly (no choice). Two next_options
## means the player chooses again at the next blacksmith visit.

@export_group("Identity")
@export var upgrade_name: String = "":
	set(new_upgrade_name):
		upgrade_name = new_upgrade_name
		emit_changed()

## Replaces the base item's description template when this node is active.
## Use {N} tokens to reference this node's effect values in order.
## Leave empty to inherit the base item's description template.
@export_multiline var description: String = "":
	set(new_description):
		description = new_description
		emit_changed()

@export_group("Effects")
## Replaces the base item's effects entirely while this node is active.
@export var effects: Array[GearEffect] = []:
	set(new_effects):
		for existing_effect: GearEffect in effects:
			if existing_effect and existing_effect.changed.is_connected(_on_effect_changed):
				existing_effect.changed.disconnect(_on_effect_changed)
		effects = new_effects
		for new_effect: GearEffect in effects:
			if new_effect:
				new_effect.changed.connect(_on_effect_changed)
		emit_changed()

@export_group("Next Upgrades")
## Upgrade options available at the next blacksmith visit after this node is chosen.
## 0 = maxed out on this path. 1 = linear (no choice). 2 = branching choice.
@export var next_options: Array[GearUpgradeNode] = []:
	set(new_next_options):
		next_options = new_next_options
		emit_changed()

func _on_effect_changed() -> void:
	emit_changed()
