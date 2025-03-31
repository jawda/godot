class_name Stats extends PanelContainer


@onready var level_value_label: Label = %Level_Value_Label
@onready var xp_value_label: Label = %XP_Value_Label
@onready var attack_value_label: Label = %Attack_Value_Label
@onready var defense_value_label: Label = %Defense_Value_Label
@onready var attack_value_change_label: Label = %Attack_Value_Change_Label
@onready var defense_value_change_label: Label = %Defense_Value_Change_Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PauseMenu.shown.connect( update_stats )
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
	attack_value_label.text = str( _p.attack )
	defense_value_label.text = str( _p.defense )
	pass
