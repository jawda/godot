class_name GearTab
extends Control

# ── Node references ────────────────────────────────────────────────────────────

@onready var _helmet_slot: Button      = $ContentMargin/ContentLayout/SlotGrid/HelmetSlot
@onready var _necklace_slot: Button    = $ContentMargin/ContentLayout/SlotGrid/NecklaceSlot
@onready var _ring_left_slot: Button   = $ContentMargin/ContentLayout/SlotGrid/RingLeftSlot
@onready var _ring_right_slot: Button  = $ContentMargin/ContentLayout/SlotGrid/RingRightSlot
@onready var _armor_slot: Button       = $ContentMargin/ContentLayout/SlotGrid/ArmorSlot
@onready var _boots_slot: Button       = $ContentMargin/ContentLayout/SlotGrid/BootsSlot
@onready var _weapon_right_slot: Button = $ContentMargin/ContentLayout/SlotGrid/WeaponRightSlot
@onready var _weapon_left_slot: Button  = $ContentMargin/ContentLayout/SlotGrid/WeaponLeftSlot

@onready var _helmet_status: Label      = $ContentMargin/ContentLayout/SlotGrid/HelmetSlot/SlotVBox/SlotStatus
@onready var _necklace_status: Label    = $ContentMargin/ContentLayout/SlotGrid/NecklaceSlot/SlotVBox/SlotStatus
@onready var _ring_left_status: Label   = $ContentMargin/ContentLayout/SlotGrid/RingLeftSlot/SlotVBox/SlotStatus
@onready var _ring_right_status: Label  = $ContentMargin/ContentLayout/SlotGrid/RingRightSlot/SlotVBox/SlotStatus
@onready var _armor_status: Label       = $ContentMargin/ContentLayout/SlotGrid/ArmorSlot/SlotVBox/SlotStatus
@onready var _boots_status: Label       = $ContentMargin/ContentLayout/SlotGrid/BootsSlot/SlotVBox/SlotStatus
@onready var _weapon_right_status: Label = $ContentMargin/ContentLayout/SlotGrid/WeaponRightSlot/SlotVBox/SlotStatus
@onready var _weapon_left_status: Label  = $ContentMargin/ContentLayout/SlotGrid/WeaponLeftSlot/SlotVBox/SlotStatus

@onready var _gear_name: Label            = $ContentMargin/ContentLayout/DetailPanel/DetailContent/GearName
@onready var _gear_description: RichTextLabel = $ContentMargin/ContentLayout/DetailPanel/DetailContent/GearDescription

# ── Internal state ─────────────────────────────────────────────────────────────

var _character_save: CharacterSaveData

func _ready() -> void:
	_helmet_slot.mouse_entered.connect(_on_helmet_slot_mouse_entered)
	_necklace_slot.mouse_entered.connect(_on_necklace_slot_mouse_entered)
	_ring_left_slot.mouse_entered.connect(_on_ring_left_slot_mouse_entered)
	_ring_right_slot.mouse_entered.connect(_on_ring_right_slot_mouse_entered)
	_armor_slot.mouse_entered.connect(_on_armor_slot_mouse_entered)
	_boots_slot.mouse_entered.connect(_on_boots_slot_mouse_entered)
	_weapon_right_slot.mouse_entered.connect(_on_weapon_right_slot_mouse_entered)
	_weapon_left_slot.mouse_entered.connect(_on_weapon_left_slot_mouse_entered)

func populate(character_save: CharacterSaveData) -> void:
	_character_save = character_save
	_refresh_slots()
	_gear_name.text = "Hover over a slot"
	_gear_description.text = ""

func _refresh_slots() -> void:
	_helmet_status.text      = _slot_status_text(_character_save.helmet)
	_necklace_status.text    = _slot_status_text(_character_save.necklace)
	_ring_left_status.text   = _slot_status_text(_character_save.ring_left)
	_ring_right_status.text  = _slot_status_text(_character_save.ring_right)
	_armor_status.text       = _slot_status_text(_character_save.armor)
	_boots_status.text       = _slot_status_text(_character_save.boots)
	_weapon_right_status.text = _slot_status_text(_character_save.weapon_right)
	_weapon_left_status.text  = _slot_status_text(_character_save.weapon_left)

func _slot_status_text(owned_gear: OwnedGear) -> String:
	return "Empty" if owned_gear == null else owned_gear.get_display_name()

func _show_gear_info(owned_gear: OwnedGear, slot_name: String) -> void:
	if owned_gear == null:
		_gear_name.text = slot_name + "  —  Empty"
		_gear_description.text = "No item equipped in this slot."
	else:
		_gear_name.text = owned_gear.get_display_name()
		_gear_description.text = owned_gear.get_description()

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

func _on_boots_slot_mouse_entered() -> void:
	_show_gear_info(_character_save.boots if _character_save else null, "Boots")

func _on_weapon_right_slot_mouse_entered() -> void:
	_show_gear_info(_character_save.weapon_right if _character_save else null, "Weapon (Right)")

func _on_weapon_left_slot_mouse_entered() -> void:
	_show_gear_info(_character_save.weapon_left if _character_save else null, "Weapon (Left)")
