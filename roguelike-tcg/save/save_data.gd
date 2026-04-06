class_name SaveData
extends Resource

## One entry per character the player has started a run with.
@export var character_saves: Array[CharacterSaveData] = []

## Returns the CharacterSaveData matching the given character_id, or null if not found.
func get_character_save(character_id: String) -> CharacterSaveData:
	for character_save: CharacterSaveData in character_saves:
		if character_save.character_id == character_id:
			return character_save
	return null
