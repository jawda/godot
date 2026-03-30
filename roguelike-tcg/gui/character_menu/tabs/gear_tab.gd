class_name GearTab
extends Control

# ── Node references ────────────────────────────────────────────────────────────

@onready var _helmet_slot: Button = $ContentMargin/ContentLayout/SlotGrid/HelmetSlot
@onready var _necklace_slot: Button = $ContentMargin/ContentLayout/SlotGrid/NecklaceSlot
@onready var _ring_left_slot: Button = $ContentMargin/ContentLayout/SlotGrid/RingLeftSlot
@onready var _ring_right_slot: Button = $ContentMargin/ContentLayout/SlotGrid/RingRightSlot
@onready var _armor_slot: Button = $ContentMargin/ContentLayout/SlotGrid/ArmorSlot
@onready var _weapon_slot: Button = $ContentMargin/ContentLayout/SlotGrid/WeaponSlot

@onready var _helmet_status: Label = $ContentMargin/ContentLayout/SlotGrid/HelmetSlot/SlotVBox/SlotStatus
@onready var _necklace_status: Label = $ContentMargin/ContentLayout/SlotGrid/NecklaceSlot/SlotVBox/SlotStatus
@onready var _ring_left_status: Label = $ContentMargin/ContentLayout/SlotGrid/RingLeftSlot/SlotVBox/SlotStatus
@onready var _ring_right_status: Label = $ContentMargin/ContentLayout/SlotGrid/RingRightSlot/SlotVBox/SlotStatus
@onready var _armor_status: Label = $ContentMargin/ContentLayout/SlotGrid/ArmorSlot/SlotVBox/SlotStatus
@onready var _weapon_status: Label = $ContentMargin/ContentLayout/SlotGrid/WeaponSlot/SlotVBox/SlotStatus

@onready var _gear_name: Label = $ContentMargin/ContentLayout/DetailPanel/DetailContent/GearName
@onready var _gear_description: RichTextLabel = $ContentMargin/ContentLayout/DetailPanel/DetailContent/GearDescription

# ── Internal state ─────────────────────────────────────────────────────────────

var _character_save: CharacterSaveData

func _ready() -> void:
	_helmet_slot.mouse_entered.connect(_on_helmet_slot_mouse_entered)
	_necklace_slot.mouse_entered.connect(_on_necklace_slot_mouse_entered)
	_ring_left_slot.mouse_entered.connect(_on_ring_left_slot_mouse_entered)
	_ring_right_slot.mouse_entered.connect(_on_ring_right_slot_mouse_entered)
	_armor_slot.mouse_entered.connect(_on_armor_slot_mouse_entered)
	_weapon_slot.mouse_entered.connect(_on_weapon_slot_mouse_entered)

func populate(character_save: CharacterSaveData) -> void:
	_character_save = character_save
	_refresh_slots()
	_gear_name.text = "Hover over a slot"
	_gear_description.text = ""

func _refresh_slots() -> void:
	_helmet_status.text = _slot_status_text(_character_save.helmet)
	_necklace_status.text = _slot_status_text(_character_save.necklace)
	_ring_left_status.text = _slot_status_text(_character_save.ring_left)
	_ring_right_status.text = _slot_status_text(_character_save.ring_right)
	_armor_status.text = _slot_status_text(_character_save.armor)
	_weapon_status.text = _slot_status_text(_character_save.weapon)

func _slot_status_text(gear_data: GearData) -> String:
	return "Empty" if gear_data == null else gear_data.gear_name

func _show_gear_info(gear_data: GearData, slot_name: String) -> void:
	if gear_data == null:
		_gear_name.text = slot_name + "  —  Empty"
		_gear_description.text = "No item equipped in this slot."
	else:
		_gear_name.text = gear_data.gear_name
		_gear_description.text = gear_data.get_description(gear_data.upgraded)

# ── Slot hover handlers ────────────────────────────────────────────────────────

func _on_helmet_slot_mouse_entered() -> void:
	_show_gear_info(_character_save.helmet if _character_save else null, "Helmet")

func _on_necklace_slot_mouse_entered() -> void:
	_show_gear_info(_character_save.necklace if _character_save else null, "Necklace")

func _on_ring_left_slot_mouse_entered() -> void:
	_show_gear_info(_character_save.ring_left if _character_save else null, "Ring (Left)")

func _on_ring_right_slot_mouse_entered() -> void:
	_show_gear_info(_character_save.ring_right if _character_save else null, "Ring (Right)")

func _on_armor_slot_mouse_entered() -> void:
	_show_gear_info(_character_save.armor if _character_save else null, "Armor")

func _on_weapon_slot_mouse_entered() -> void:
	_show_gear_info(_character_save.weapon if _character_save else null, "Weapon")
