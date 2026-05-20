class_name StatsTab
extends Control

signal level_up_pressed

const COLOR_BASE: Color  = Color(0.88, 0.84, 0.96, 1.0)
const COLOR_BONUS: Color = Color(0.95, 0.82, 0.42, 1.0)

# ── Node references ────────────────────────────────────────────────────────────

@onready var _character_name: Label          = $ContentMargin/OuterVBox/CharacterName
@onready var _level_xp_label: Label          = $ContentMargin/OuterVBox/LevelXP
@onready var _portrait_panel: PanelContainer = $ContentMargin/OuterVBox/ContentLayout/PortraitPanel
@onready var _level_up_button: Button        = $ContentMargin/OuterVBox/LevelUpButton

@onready var _strength_value: Label     = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/StrengthRow/StatValue
@onready var _dexterity_value: Label    = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/DexterityRow/StatValue
@onready var _constitution_value: Label = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/ConstitutionRow/StatValue
@onready var _intelligence_value: Label = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/IntelligenceRow/StatValue
@onready var _faith_value: Label        = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/FaithRow/StatValue
@onready var _crit_chance_value: Label  = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/CritChanceRow/StatValue
@onready var _health_value: Label       = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/HealthRow/StatValue
@onready var _gold_value: Label         = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/GoldRow/StatValue

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	await get_tree().process_frame
	var portrait_height: float = _portrait_panel.size.y
	_portrait_panel.custom_minimum_size = Vector2(portrait_height, portrait_height)
	_level_up_button.pressed.connect(func() -> void: level_up_pressed.emit())

# ── Public API ─────────────────────────────────────────────────────────────────

func populate(player_data: PlayerData, run_data: RunSaveData) -> void:
	_character_name.text = player_data.character_name
	if run_data != null:
		var xp_needed: int = 100 * run_data.level
		_level_xp_label.text = "Level %d  —  %d / %d XP" % [run_data.level, run_data.xp, xp_needed]
	else:
		_level_xp_label.text = "Level 1"

	_level_up_button.visible = run_data != null and run_data.pending_stat_choices > 0
	if _level_up_button.visible and run_data.pending_stat_choices > 1:
		_level_up_button.text = "⬆  Level Up — %d stat boosts available" % run_data.pending_stat_choices
	else:
		_level_up_button.text = "⬆  Level Up — Choose a Stat Boost"

	var gear_bonuses: Dictionary = _compute_gear_bonuses(run_data)
	var run_bonuses: Dictionary  = _compute_run_bonuses(run_data)

	_set_stat(_strength_value,     player_data.strength,     gear_bonuses.get("strength", 0)     + run_bonuses.get("strength", 0))
	_set_stat(_dexterity_value,    player_data.dexterity,    gear_bonuses.get("dexterity", 0)    + run_bonuses.get("dexterity", 0))
	_set_stat(_constitution_value, player_data.constitution, gear_bonuses.get("constitution", 0) + run_bonuses.get("constitution", 0))
	_set_stat(_faith_value,        player_data.faith,        gear_bonuses.get("faith", 0)        + run_bonuses.get("faith", 0))

	# Intelligence is not yet implemented — always show base with a note.
	_intelligence_value.text = str(player_data.intelligence) + " (TBD)"
	_intelligence_value.add_theme_color_override("font_color", COLOR_BASE)

	_crit_chance_value.text = "%.1f%%" % player_data.base_crit_chance
	_crit_chance_value.add_theme_color_override("font_color", COLOR_BASE)

	if run_data == null:
		var base_max_health: int = player_data.base_max_health + \
				(player_data.constitution + gear_bonuses.get("constitution", 0)) * \
				CombatPlayer.HP_PER_CONSTITUTION
		_health_value.text = str(base_max_health) + " / " + str(base_max_health)
		_gold_value.text = "—"
	else:
		_health_value.text = str(run_data.current_health) + " / " + str(run_data.current_max_health)
		_gold_value.text = str(run_data.gold)
	_health_value.add_theme_color_override("font_color", COLOR_BASE)
	_gold_value.add_theme_color_override("font_color", COLOR_BASE)

# ── Helpers ────────────────────────────────────────────────────────────────────

func _set_stat(label: Label, base_value: int, gear_bonus: int) -> void:
	if gear_bonus > 0:
		label.text = "%d  (+%d)" % [base_value + gear_bonus, gear_bonus]
		label.add_theme_color_override("font_color", COLOR_BONUS)
	else:
		label.text = str(base_value)
		label.add_theme_color_override("font_color", COLOR_BASE)

## Returns a dictionary of stat_name -> level-up bonus from the current run.
func _compute_run_bonuses(run_data: RunSaveData) -> Dictionary:
	if run_data == null:
		return {}
	return {
		"strength":     run_data.bonus_strength,
		"dexterity":    run_data.bonus_dexterity,
		"constitution": run_data.bonus_constitution,
		"intelligence": run_data.bonus_intelligence,
		"faith":        run_data.bonus_faith,
	}

## Returns a dictionary of stat_name -> total passive bonus from all equipped gear.
func _compute_gear_bonuses(run_data: RunSaveData) -> Dictionary:
	var bonuses: Dictionary = {}
	if run_data == null:
		return bonuses
	var slots: Array = [
		run_data.helmet, run_data.necklace,
		run_data.ring_left, run_data.ring_right,
		run_data.armor, run_data.boots,
		run_data.weapon_right, run_data.weapon_left,
	]
	for slot_item: Variant in slots:
		if not (slot_item is OwnedGear):
			continue
		for gear_effect: GearEffect in (slot_item as OwnedGear).get_active_effects():
			if gear_effect.trigger == GearEffect.Trigger.PASSIVE \
					and gear_effect.effect_type == GearEffect.EffectType.STAT_BONUS \
					and not gear_effect.param.is_empty():
				bonuses[gear_effect.param] = bonuses.get(gear_effect.param, 0) + gear_effect.value
	return bonuses
