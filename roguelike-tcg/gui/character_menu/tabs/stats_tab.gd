class_name StatsTab
extends Control

# ── Node references ────────────────────────────────────────────────────────────

@onready var _character_name: Label = $ContentMargin/OuterVBox/CharacterName
@onready var _character_class: Label = $ContentMargin/OuterVBox/CharacterClass
@onready var _portrait_panel: PanelContainer = $ContentMargin/OuterVBox/ContentLayout/PortraitPanel

@onready var _strength_value: Label = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/StrengthRow/StatValue
@onready var _dexterity_value: Label = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/DexterityRow/StatValue
@onready var _constitution_value: Label = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/ConstitutionRow/StatValue
@onready var _intelligence_value: Label = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/IntelligenceRow/StatValue
@onready var _faith_value: Label = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/FaithRow/StatValue
@onready var _crit_chance_value: Label = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/CritChanceRow/StatValue
@onready var _health_value: Label = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/HealthRow/StatValue
@onready var _gold_value: Label = $ContentMargin/OuterVBox/ContentLayout/RightColumn/StatsPanel/StatsContent/GoldRow/StatValue

func _ready() -> void:
	await get_tree().process_frame
	var h := _portrait_panel.size.y
	_portrait_panel.custom_minimum_size = Vector2(h, h)

func populate(player_data: PlayerData, run_data: RunSaveData) -> void:
	_character_name.text = player_data.character_name
	_character_class.text = player_data.character_class

	_strength_value.text = str(player_data.strength)
	_dexterity_value.text = str(player_data.dexterity)
	_constitution_value.text = str(player_data.constitution)

	# Intelligence and Faith effects are not yet implemented.
	_intelligence_value.text = str(player_data.intelligence) + " (TBD)"
	_faith_value.text = str(player_data.faith) + " (TBD)"

	_crit_chance_value.text = "%.1f%%" % player_data.base_crit_chance

	if run_data == null:
		_health_value.text = str(player_data.base_max_health) + " / " + str(player_data.base_max_health)
		_gold_value.text = "—"
	else:
		_health_value.text = str(run_data.current_health) + " / " + str(run_data.current_max_health)
		_gold_value.text = str(run_data.gold)
