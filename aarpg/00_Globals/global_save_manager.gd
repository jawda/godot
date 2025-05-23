extends Node


const SAVE_PATH = "user://"

signal game_loaded
signal game_saved

## setting up a json object for our save
var current_save : Dictionary = {
	scene_path = "",
	player = {
		level = 1,
		xp = 0,
		attack = 0,
		defense = 0,
		hp = 1,
		max_hp = 1,
		pos_x = 0,
		pos_y = 0
	},
	items = [],
	persistence = [],
	quests = [
		#{ title = "not found", is_complete = false, completed_steps = [''] }
	],
}

## pause menu save game button fired
func  save_game() -> void:
	update_player_data() ## update player info
	update_scene_path() ## update scene info
	update_item_data() ## update item info
	update_quest_data()
	var file := FileAccess.open(SAVE_PATH + "save.sav", FileAccess.WRITE )
	var save_json = JSON.stringify( current_save )
	file.store_line( save_json )
	game_saved.emit()
	#print("save_game")
	pass
	
func get_save_file() -> FileAccess:
	return FileAccess.open( SAVE_PATH + "save.sav", FileAccess.READ )
	
## pause menu load game button fired
func load_game() -> void:
	var file := get_save_file()
	var json := JSON.new()
	json.parse( file.get_line() )
	var save_dict : Dictionary = json.get_data() as Dictionary
	current_save = save_dict
	
	LevelManager.load_new_level( current_save.scene_path, "", Vector2.ZERO )	
	
	##while screne is blacked out
	await LevelManager.level_load_started
	
	##set player position from json file
	PlayerManager.set_player_position(Vector2(current_save.player.pos_x,current_save.player.pos_y ))
	PlayerManager.set_health(current_save.player.hp, current_save.player.max_hp)
	var p : Player = PlayerManager.player
	p.level = current_save.player.level
	p.xp = current_save.player.xp
	p.attack = current_save.player.attack
	p.defense = current_save.player.defense
	PlayerManager.INVENTORY_DATA.parse_save_data( current_save.items )
	
	QuestManager.current_quests = current_save.quests
	
	await LevelManager.level_loaded
	
	game_loaded.emit()
	#print("load_game")
	pass
	
## update player info
func update_player_data() -> void:
	var p : Player = PlayerManager.player
	current_save.player.hp = p.hp
	current_save.player.max_hp = p.max_hp
	current_save.player.pos_x = p.global_position.x
	current_save.player.pos_y = p.global_position.y
	current_save.player.level = p.level
	current_save.player.xp = p.xp
	current_save.player.attack = p.attack
	current_save.player.defense = p.defense

## update scene info
func update_scene_path() -> void:
	var p : String = ""
	## get current level
	for c in get_tree().root.get_children():
		if c is Level:
			p = c.scene_file_path
	current_save.scene_path = p

## update inventory data
func update_item_data() -> void:
	current_save.items = PlayerManager.INVENTORY_DATA.get_save_data()

func update_quest_data() -> void:
	current_save.quests = QuestManager.current_quests
	pass
	
func add_persistent_value( value : String ) -> void:
	if check_persistent_value( value ) == false:
		current_save.persistence.append( value )
		
	pass
	
func check_persistent_value( value : String ) -> bool:
	var p = current_save.persistence as Array
	return p.has( value )
	
func remove_persistent_value( value : String ) -> void:
	var p = current_save.persistence as Array
	p.erase( value )
	pass
