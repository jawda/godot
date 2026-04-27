class_name RestSite
extends Control

## Rest site scene. Shown when the player enters a REST room.
##
## The player may use any combination of the available options before leaving.
## Each option (Recover, Reflect, Remove) can only be used once per visit.
##
## NOTE: Card upgrades (Reflect) are applied to the shared CardData resource
## in memory and persist for this run session. The save system does not yet
## persist per-card upgrade state across reloads — tracked as a future task.

signal room_completed

# ── Preloads ───────────────────────────────────────────────────────────────────
# Explicit preload brings CardPicker into scope before the @onready type
# annotation is checked. Without this, Godot may parse rest_site.gd before
# card_picker.gd's class_name has been registered, causing a parse error.

const CardPicker := preload("res://gui/rest_site/card_picker.gd")

# ── Node references ─────────────────────────────────────────────────────────────

@onready var _health_display: Label   = $Center/Panel/Padding/Contents/HealthDisplay
@onready var _recover_button: Button  = $Center/Panel/Padding/Contents/Options/Recover
@onready var _reflect_button: Button  = $Center/Panel/Padding/Contents/Options/Reflect
@onready var _remove_button: Button   = $Center/Panel/Padding/Contents/Options/RemoveCard
@onready var _swap_button: Button     = $Center/Panel/Padding/Contents/Options/SwapGear
@onready var _mastery_button: Button  = $Center/Panel/Padding/Contents/Options/ClaimMastery
@onready var _leave_button: Button    = $Center/Panel/Padding/Contents/Leave
@onready var _card_picker: CardPicker = $CardPicker

# ── State ────────────────────────────────────────────────────────────────────────

var _recovered: bool    = false
var _reflected: bool    = false
var _card_removed: bool = false

## Tracks which action the next card_chosen callback should perform.
enum _PickerMode { UPGRADE, REMOVE }
var _picker_mode: _PickerMode = _PickerMode.UPGRADE

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_recover_button.pressed.connect(_on_recover_pressed)
	_reflect_button.pressed.connect(_on_reflect_pressed)
	_remove_button.pressed.connect(_on_remove_pressed)
	_swap_button.pressed.connect(_on_swap_pressed)
	_mastery_button.pressed.connect(_on_mastery_pressed)
	_leave_button.pressed.connect(func() -> void: room_completed.emit())
	_card_picker.card_chosen.connect(_on_card_chosen)
	_refresh_ui()

# ── UI refresh ─────────────────────────────────────────────────────────────────

func _refresh_ui() -> void:
	var run: RunSaveData = RunState.active_run
	_health_display.text = "HP  %d / %d" % [run.current_health, run.current_max_health]

	var heal_amount: int = int(run.current_max_health * 0.30)
	var at_full_hp: bool = run.current_health >= run.current_max_health
	_recover_button.disabled = _recovered or at_full_hp
	if _recovered:
		_recover_button.text = "Recover  (Used)"
	elif at_full_hp:
		_recover_button.text = "Recover  (Already at full HP)"
	else:
		_recover_button.text = "Recover  — restore %d HP" % heal_amount

	var upgradeable_count: int = _get_unique_upgradeable_paths().size()
	_reflect_button.disabled = _reflected or upgradeable_count == 0
	if _reflected:
		_reflect_button.text = "Reflect  (Used)"
	elif upgradeable_count == 0:
		_reflect_button.text = "Reflect  (No cards to upgrade)"
	else:
		_reflect_button.text = "Reflect  — upgrade a card"

	var not_enough_gold: bool = run.gold < 50
	var deck_too_small: bool  = run.deck_card_paths.size() <= 1
	_remove_button.disabled = _card_removed or not_enough_gold or deck_too_small
	if _card_removed:
		_remove_button.text = "Remove a Card  (Used)"
	elif not_enough_gold:
		_remove_button.text = "Remove a Card  (Need 50g — have %dg)" % run.gold
	elif deck_too_small:
		_remove_button.text = "Remove a Card  (Deck too small)"
	else:
		_remove_button.text = "Remove a Card  — 50g  (have %dg)" % run.gold

	_mastery_button.visible = run.pending_mastery

# ── Option handlers ────────────────────────────────────────────────────────────

func _on_recover_pressed() -> void:
	var run: RunSaveData = RunState.active_run
	var heal_amount: int = int(run.current_max_health * 0.30)
	run.current_health = mini(run.current_health + heal_amount, run.current_max_health)
	_recovered = true
	SaveManager.save()
	_refresh_ui()

func _on_reflect_pressed() -> void:
	var run: RunSaveData = RunState.active_run
	var cards: Array[CardData] = []
	for i: int in run.deck_card_paths.size():
		var is_upgraded: bool = i < run.deck_card_upgrades.size() and run.deck_card_upgrades[i]
		if not is_upgraded:
			var card: CardData = load(run.deck_card_paths[i]) as CardData
			if card != null:
				cards.append(card)
	if cards.is_empty():
		return
	_picker_mode = _PickerMode.UPGRADE
	_card_picker.open("Choose a card to upgrade", cards)

func _on_remove_pressed() -> void:
	var cards: Array[CardData] = _load_all_deck_cards()
	if cards.is_empty():
		return
	_picker_mode = _PickerMode.REMOVE
	_card_picker.open("Choose a card to remove  (costs 50g)", cards)

func _on_swap_pressed() -> void:
	pass  # TODO: gear swap overlay

func _on_mastery_pressed() -> void:
	pass  # TODO: mastery claim overlay

func _on_card_chosen(card: CardData) -> void:
	match _picker_mode:
		_PickerMode.UPGRADE:
			var run: RunSaveData = RunState.active_run
			for i: int in run.deck_card_paths.size():
				if run.deck_card_paths[i] == card.resource_path:
					var already_upgraded: bool = i < run.deck_card_upgrades.size() and run.deck_card_upgrades[i]
					if not already_upgraded:
						run.deck_card_upgrades[i] = true
						break
			_reflected = true
		_PickerMode.REMOVE:
			var path: String = card.resource_path
			var index: int = RunState.active_run.deck_card_paths.find(path)
			if index >= 0:
				RunState.active_run.deck_card_paths.remove_at(index)
				if index < RunState.active_run.deck_card_upgrades.size():
					RunState.active_run.deck_card_upgrades.remove_at(index)
			RunState.active_run.gold -= 50
			_card_removed = true
	SaveManager.save()
	_refresh_ui()

# ── Card loading helpers ───────────────────────────────────────────────────────

## Returns unique card paths that have at least one unupgraded copy this run.
## Deduplicates so each card type appears once in the upgrade picker.
func _get_unique_upgradeable_paths() -> Array[String]:
	var run: RunSaveData = RunState.active_run
	var has_unupgraded: Dictionary = {}
	for i: int in run.deck_card_paths.size():
		var path: String = run.deck_card_paths[i]
		var is_upgraded: bool = i < run.deck_card_upgrades.size() and run.deck_card_upgrades[i]
		if not is_upgraded:
			has_unupgraded[path] = true
	var result: Array[String] = []
	for path: String in has_unupgraded:
		result.append(path)
	return result

## Returns one CardData per entry in deck_card_paths, including duplicates.
## Used by Remove so the player can pick which copy to cull.
func _load_all_deck_cards() -> Array[CardData]:
	var result: Array[CardData] = []
	for path: String in RunState.active_run.deck_card_paths:
		var card: CardData = load(path) as CardData
		if card != null:
			result.append(card)
	return result
