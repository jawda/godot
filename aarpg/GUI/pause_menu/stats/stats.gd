class_name Stats extends PanelContainer

var inventory : InventoryData

@onready var level_value_label: Label = %Level_Value_Label
@onready var xp_value_label: Label = %XP_Value_Label
@onready var attack_value_label: Label = %Attack_Value_Label
@onready var defense_value_label: Label = %Defense_Value_Label
@onready var attack_value_change_label: Label = %Attack_Value_Change_Label
@onready var defense_value_change_label: Label = %Defense_Value_Change_Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PauseMenu.shown.connect( update_stats )
	PauseMenu.preview_stats_changed.connect( _on_preview_stats_changed )
	inventory = PlayerManager.INVENTORY_DATA
	inventory.equipment_changed.connect( update_stats )
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_stats() -> void:
	var _p : Player = PlayerManager.player
	level_value_label.text = str( _p.level )
	
	if _p.level < PlayerManager.level_requirements.size():
		xp_value_label.text = str( _p.xp ) + "/" + str( PlayerManager.level_requirements[ _p.level ])
	else:
		xp_value_label.text = "MAX LVL"
	attack_value_label.text = str( _p.attack + inventory.get_attack_bonus() )
	defense_value_label.text = str( _p.defense + inventory.get_defence_bonus() )
	
	pass

func _on_preview_stats_changed( item : ItemData ) -> void:
	attack_value_change_label.text = ""
	defense_value_change_label.text = ""
	
	if not item is EquipableItemData:
		return
	var equipment : EquipableItemData = item
	var attack_delta : int = inventory.get_attack_bonus_diff( equipment )
	var defense_delta : int = inventory.get_defense_bonus_diff( equipment )
	
	update_change_label(attack_value_change_label, attack_delta)
	update_change_label(defense_value_change_label, defense_delta)
	pass

func update_change_label( label : Label, value : int) -> void:
	if value > 0:
		label.text = "+" + str(value)
		label.modulate = Color.LIGHT_GREEN
	elif value < 0:
		label.text = str( value )
		label.modulate = Color.INDIAN_RED
	pass
