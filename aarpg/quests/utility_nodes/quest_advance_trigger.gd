@tool
@icon("res://quests/utility_nodes/icons/quest_advance.png")
class_name QuestAdvanceTrigger extends QuestNode

@export_category( "Parent Signal Connection")
@export var signal_name : String = ""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	$Sprite2D.queue_free()
	if signal_name != "":
		if get_parent().has_signal( signal_name ):
			get_parent().connect( signal_name, advance_quest )
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func advance_quest() -> void:
	if linked_quest == null:
		return
	var _title : String = linked_quest.title
	var _step : String = get_step()
	if _step == "N/A":
		_step = ""
		
	QuestManager.update_quest( _title, _step, quest_complete )
	pass


func _on_pressure_plate_activated() -> void:
	pass # Replace with function body.
