class_name CharacterStatsData
extends Resource

## Serializable resource holding base stat values for a character.
## Use this to define stat profiles for player, enemies, NPCs, etc.

@export_group("Identity")
@export var character_name: String = "Unknown"
@export var character_class: String = "Unknown"
@export var portrait: Texture2D

@export_group("Combat")
@export_range(1, 99) var strength: int = 10
@export_range(1, 99) var dexterity: int = 10
@export_range(1, 99) var vigor: int = 10

@export_group("Magic & Influence")
@export_range(1, 99) var faith: int = 10
@export_range(1, 99) var intelligence: int = 10
@export_range(1, 99) var charisma: int = 10
