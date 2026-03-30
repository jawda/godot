@tool
class_name GearData
extends Resource

enum GearSlot { HELMET, NECKLACE, RING, ARMOR, WEAPON }
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
@export var upgraded: bool = false:
	set(new_upgraded):
		upgraded = new_upgraded
		emit_changed()

func _on_effect_changed() -> void:
	emit_changed()

## Returns gear_description with {N} tokens replaced by the resolved effect values.
func get_description(is_upgraded: bool = false) -> String:
	var result: String = gear_description
	for effect_index in effects.size():
		if effects[effect_index]:
			result = result.replace("{%d}" % effect_index, str(effects[effect_index].resolved_value(is_upgraded)))
	return result
