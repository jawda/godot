@tool
class_name GearData
extends Resource

enum GearSlot { HELMET, NECKLACE, RING, ARMOR, BOOTS, WEAPON_RIGHT, WEAPON_LEFT }
enum Rarity    { COMMON, UNCOMMON, RARE, MYTHIC, SPECIAL }

@export_group("Gear Data")
@export var gear_name: String = "New Item":
	set(new_gear_name):
		gear_name = new_gear_name
		emit_changed()

@export var gear_slot: GearSlot = GearSlot.ARMOR:
	set(new_gear_slot):
		gear_slot = new_gear_slot
		emit_changed()

@export var rarity: Rarity = Rarity.COMMON:
	set(new_rarity):
		rarity = new_rarity
		emit_changed()

## Description template. Use {0}, {1}, … to reference gear effect values in order,
## the same way card descriptions work. See documents/creating-a-card.md §Step 4.
@export_multiline var gear_description: String = "":
	set(new_gear_description):
		gear_description = new_gear_description
		emit_changed()

## The passive and triggered effects this item provides while equipped.
@export var effects: Array[GearEffect] = []:
	set(new_effects):
		for existing_effect in effects:
			if existing_effect and existing_effect.changed.is_connected(_on_effect_changed):
				existing_effect.changed.disconnect(_on_effect_changed)
		effects = new_effects
		for new_effect in effects:
			if new_effect:
				new_effect.changed.connect(_on_effect_changed)
		emit_changed()

@export_group("Upgrade")
## First-level upgrade choices available at a blacksmith. Empty = this item cannot be upgraded.
@export var upgrade_options: Array[GearUpgradeNode] = []:
	set(new_upgrade_options):
		upgrade_options = new_upgrade_options
		emit_changed()

func _on_effect_changed() -> void:
	emit_changed()

## Returns the description with {N} tokens replaced by effect values.
## Pass the active GearUpgradeNode to resolve a specific upgrade state,
## or omit to get the base item description.
func get_description(active_node: GearUpgradeNode = null) -> String:
	var template: String = gear_description
	var active_effects: Array[GearEffect] = effects
	if active_node != null:
		if not active_node.description.is_empty():
			template = active_node.description
		active_effects = active_node.effects
	var result: String = template
	for effect_index: int in active_effects.size():
		if active_effects[effect_index]:
			result = result.replace("{%d}" % effect_index, str(active_effects[effect_index].value))
	return result
