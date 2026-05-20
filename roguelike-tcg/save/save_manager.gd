# AutoLoad singleton — no class_name (Godot forbids it on AutoLoad scripts).
# Register as "SaveManager" in Project Settings → Autoload.
extends Node

const SLOT_COUNT: int = 3
const SLOT_PATH_TEMPLATE: String = "user://save_slot_%d.tres"

## All three save slots. Entries are SaveData or null for empty slots.
var _slots: Array = []
var _active_slot_index: int = -1

## The SaveData for the currently active slot. Null if no slot is selected.
var save_data: SaveData:
	get:
		if _active_slot_index < 0 or _active_slot_index >= SLOT_COUNT:
			return null
		return _slots[_active_slot_index] as SaveData

func _ready() -> void:
	_slots.resize(SLOT_COUNT)
	for slot_index: int in range(SLOT_COUNT):
		_load_slot(slot_index)

func _load_slot(slot_index: int) -> void:
	var path: String = SLOT_PATH_TEMPLATE % slot_index
	if ResourceLoader.exists(path):
		_slots[slot_index] = ResourceLoader.load(path) as SaveData
	else:
		_slots[slot_index] = null

## Returns the SaveData for a given slot index, or null if the slot is empty.
func get_slot(slot_index: int) -> SaveData:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return null
	return _slots[slot_index] as SaveData

## Activates a slot for all subsequent save/load operations.
## Creates a blank SaveData if the slot was empty.
func set_active_slot(slot_index: int) -> void:
	_active_slot_index = slot_index
	if _slots[slot_index] == null:
		_slots[slot_index] = SaveData.new()

## Persists the active slot to disk.
func save() -> void:
	if save_data == null or _active_slot_index < 0:
		return
	ResourceSaver.save(save_data, SLOT_PATH_TEMPLATE % _active_slot_index)

## Deletes the save file for a slot and clears it in memory.
func delete_slot(slot_index: int) -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir != null:
		dir.remove("save_slot_%d.tres" % slot_index)
	_slots[slot_index] = null
	if _active_slot_index == slot_index:
		_active_slot_index = -1

## Returns the CharacterSaveData for the given character_id in the active slot,
## creating and saving one if it doesn't exist yet.
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
