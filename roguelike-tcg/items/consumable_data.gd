class_name ConsumableData
extends Resource

## Data resource defining a single consumable item (potion, tincture, etc.).
## Consumables are held in the potion belt (3 slots) and used during a run.
## They persist between floors but are lost on death.

enum UseTiming {
	ANYWHERE,     ## Can be used from the dungeon map or during combat (player turn only).
	COMBAT_ONLY,  ## Can only be used during combat on the player's turn.
}

@export_group("Identity")
@export var item_name: String = "":
	set(new_item_name):
		item_name = new_item_name
		emit_changed()

@export_multiline var description: String = "":
	set(new_description):
		description = new_description
		emit_changed()

## Small icon shown in the potion belt during combat.
@export var icon: Texture2D:
	set(new_icon):
		icon = new_icon
		emit_changed()

@export_group("Behaviour")
@export var use_timing: UseTiming = UseTiming.ANYWHERE:
	set(new_use_timing):
		use_timing = new_use_timing
		emit_changed()

## All effects applied in order when this item is consumed.
@export var effects: Array[ConsumableEffect] = []:
	set(new_effects):
		for existing_effect: ConsumableEffect in effects:
			if existing_effect and existing_effect.changed.is_connected(_on_effect_changed):
				existing_effect.changed.disconnect(_on_effect_changed)
		effects = new_effects
		for new_effect: ConsumableEffect in effects:
			if new_effect:
				new_effect.changed.connect(_on_effect_changed)
		emit_changed()

func _on_effect_changed() -> void:
	emit_changed()
