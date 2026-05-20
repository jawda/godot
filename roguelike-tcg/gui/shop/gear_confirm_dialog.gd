class_name GearConfirmDialog
extends Control

## Confirmation overlay shown before equipping gear from the shop.
## show_for_equip() populates the content; emits confirmed or cancelled.

signal confirmed
signal cancelled

# ── Node references ────────────────────────────────────────────────────────────

@onready var _item_name: Label    = $Dialog/Contents/ItemName
@onready var _slot_info: Label    = $Dialog/Contents/SlotInfo
@onready var _equip_button: Button = $Dialog/Contents/Buttons/Equip
@onready var _cancel_button: Button = $Dialog/Contents/Buttons/Cancel

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_equip_button.pressed.connect(_on_equip_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()

# ── Public API ─────────────────────────────────────────────────────────────────

func show_for_equip(new_gear: GearData, slot_label: String, displaced: OwnedGear) -> void:
	_item_name.text = new_gear.gear_name
	if displaced != null:
		_slot_info.text = "Replaces %s in %s slot." % [displaced.get_display_name(), slot_label]
		_equip_button.text = "Replace"
	else:
		_slot_info.text = "Equip to %s slot." % slot_label
		_equip_button.text = "Equip"
	show()

# ── Handlers ───────────────────────────────────────────────────────────────────

func _on_equip_pressed() -> void:
	hide()
	confirmed.emit()

func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()
