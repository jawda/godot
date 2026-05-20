class_name OwnedGear
extends Resource

## Runtime wrapper around a GearData resource that tracks an individual item's upgrade state.
##
## GearData is shared, static data (the item template). OwnedGear is the per-character,
## per-item record of which upgrade path was taken. This is what lives in save files —
## multiple characters can own the same base item but have upgraded it differently.

@export var base_gear: GearData = null

## The sequence of choices made at each blacksmith visit.
## Index 0 = first upgrade, index 1 = second, and so on.
## A value of 0 means the player chose the first option; 1 means the second.
@export var upgrade_path: Array[int] = []

# ── State traversal ────────────────────────────────────────────────────────────

## Returns the active upgrade node for this item's current state, or null if unupgraded.
func get_current_node() -> GearUpgradeNode:
	if upgrade_path.is_empty() or base_gear == null:
		return null
	var options: Array[GearUpgradeNode] = base_gear.upgrade_options
	var current_node: GearUpgradeNode = null
	for choice: int in upgrade_path:
		if choice >= options.size():
			return current_node
		current_node = options[choice]
		options = current_node.next_options
	return current_node

## Returns the upgrade options available at the next blacksmith visit.
## Empty array means this item is fully maxed on its current path.
func get_next_options() -> Array[GearUpgradeNode]:
	var current_node: GearUpgradeNode = get_current_node()
	if current_node == null:
		return base_gear.upgrade_options if base_gear != null else []
	return current_node.next_options

## Returns true if this item has at least one upgrade option remaining.
func can_upgrade() -> bool:
	return not get_next_options().is_empty()

## Returns the number of upgrades applied (0 = base item, unupgraded).
func upgrade_depth() -> int:
	return upgrade_path.size()

# ── Active stats ───────────────────────────────────────────────────────────────

## Returns the effects currently active on this item.
## Uses the active node's effects if upgraded, otherwise the base item's effects.
func get_active_effects() -> Array[GearEffect]:
	var current_node: GearUpgradeNode = get_current_node()
	if current_node != null:
		return current_node.effects
	return base_gear.effects if base_gear != null else []

## Returns the display name — the active node's name if upgraded, else the base item name.
func get_display_name() -> String:
	var current_node: GearUpgradeNode = get_current_node()
	if current_node != null and not current_node.upgrade_name.is_empty():
		return current_node.upgrade_name
	return base_gear.gear_name if base_gear != null else ""

## Returns the description with {N} tokens resolved against active effect values.
func get_description() -> String:
	if base_gear == null:
		return ""
	return base_gear.get_description(get_current_node())

# ── Upgrade actions ────────────────────────────────────────────────────────────

## Applies an upgrade by recording the chosen option index.
## option_index must be a valid index into get_next_options().
func apply_upgrade(option_index: int) -> void:
	upgrade_path.append(option_index)

## Returns the gold cost to upgrade this item at the next blacksmith visit.
## Cost scales quadratically with upgrade depth and linearly with item rarity.
func get_upgrade_cost() -> int:
	if base_gear == null:
		return 0
	const BASE_COST: int = 50
	const RARITY_MULTIPLIERS: Dictionary = {
		GearData.Rarity.COMMON:   1.0,
		GearData.Rarity.UNCOMMON: 1.5,
		GearData.Rarity.RARE:     2.0,
		GearData.Rarity.MYTHIC:   3.0,
	}
	var depth: int = upgrade_path.size() + 1
	var rarity_multiplier: float = RARITY_MULTIPLIERS.get(base_gear.rarity, 1.0)
	return int(BASE_COST * depth * depth * rarity_multiplier)
