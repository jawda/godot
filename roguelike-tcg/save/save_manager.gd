# Add as autoload named SaveManager in Project → Project Settings → Autoload.
# class_name is intentionally omitted — the autoload name serves as the global identifier.
extends Node

const SAVE_PATH: String = "user://save.tres"

var save_data: SaveData

func _ready() -> void:
	load_save()

func load_save() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		save_data = ResourceLoader.load(SAVE_PATH) as SaveData
	else:
		save_data = SaveData.new()

func save() -> void:
	ResourceSaver.save(save_data, SAVE_PATH)

## Returns the CharacterSaveData for the given character_id, creating and saving one if it doesn't exist yet.
func get_or_create_character_save(character_id: String) -> CharacterSaveData:
	var existing_save: CharacterSaveData = save_data.get_character_save(character_id)
	if existing_save:
		return existing_save

	var new_character_save: CharacterSaveData = CharacterSaveData.new()
	new_character_save.character_id = character_id
	save_data.character_saves.append(new_character_save)
	save()
	return new_character_save

## Clears the active run on the character's save and persists.
func end_run(character_id: String) -> void:
	var character_save: CharacterSaveData = save_data.get_character_save(character_id)
	if character_save:
		character_save.active_run = null
	save()
