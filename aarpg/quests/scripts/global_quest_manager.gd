## QUEST MANAGER - GLOBAL SCRIPT
extends Node

signal quest_updated( q : Quest )

const QUEST_DATA_LOCATION : String = "res://quests/"

var quests : Array[ Quest ]

 #{title = "not found", is_complete = false, completed_steps = [''] }
var current_quests : Array


func _ready() -> void:
	#gather all quests
	gather_quest_data()
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		print( find_quest(load("res://quests/recover_lost_flute.tres") as Quest))
	pass

func gather_quest_data() -> void:
	#Gather all quest resources and add to array
	var quest_files : PackedStringArray = DirAccess.get_files_at( QUEST_DATA_LOCATION )
	quests.clear()
	for q in quest_files:
		quests.append( load( QUEST_DATA_LOCATION + "/" + q) as Quest )
		pass
	print("Quest count: ", quests.size())
	pass
	
func update_quest() -> void:
	#update the status of a quest
	pass
	
func disperse_quest_rewards() -> void:
	#Give xp and item rewards to player
	pass
	
func find_quest( _quest : Quest ) -> Dictionary:
	#Provide a quest and return the current associated with it
	for q in current_quests:
		if q.title == _quest.title:
			return q
	return { title = "not found", is_complete = false, completed_steps = [''] }
	
func find_quest_by_title( _title : String ) -> Quest:
	# Take title and find associated Quest resource
	return null
	
func get_quest_index_by_title( _title : String ) -> int:
	# Find quest by title name, and return index in Quests array
	return -1
	
func sort_quests() -> void:
	pass
