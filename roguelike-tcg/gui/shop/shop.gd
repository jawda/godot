class_name Shop
extends Control

signal room_completed

# Explicit preload brings CardPicker into scope before the @onready type annotation
# is checked — same pattern used in rest_site.gd.
const CardPickerScript := preload("res://gui/rest_site/card_picker.gd")
const CARD_SCENE: PackedScene = preload("res://cards/card.tscn")

const CARDS_DATA_PATH: String       = "res://cards/data"
const CONSUMABLES_DATA_PATH: String = "res://items/data"

const CARDS_TOTAL_COUNT: int   = 8
const CARDS_NEUTRAL_MAX: int   = 2
const CONSUMABLES_COUNT: int   = 3

const CARD_PRICES: Dictionary = {
	CardData.Rarity.COMMON:   50,
	CardData.Rarity.UNCOMMON: 80,
	CardData.Rarity.RARE:     140,
}
const CONSUMABLE_PRICE: int      = 40
const SERVICE_REMOVE_PRICE: int  = 75
const SERVICE_UPGRADE_PRICE: int = 100

const COLOR_SECTION: Color = Color(0.75, 0.60, 0.25, 0.65)
const COLOR_PRICE: Color   = Color(0.90, 0.78, 0.18, 1.0)
const COLOR_SOLD: Color    = Color(0.40, 0.36, 0.30, 0.55)
const COLOR_NAME: Color    = Color(0.92, 0.85, 1.0, 1.0)
const COLOR_SUB: Color     = Color(0.55, 0.48, 0.68, 1.0)

const CARD_HOVER_SCALE: Vector2 = Vector2(1.06, 1.06)

# ── Node references ────────────────────────────────────────────────────────────

@onready var _gold_display: Label           = $Panel/Contents/Header/Info/GoldDisplay
@onready var _card_row: GridContainer       = $Panel/Contents/Scroll/ShopPadding/ShopList/CardRow
@onready var _shop_list: VBoxContainer      = $Panel/Contents/Scroll/ShopPadding/ShopList
@onready var _leave_button: Button          = $Panel/Contents/Footer/Leave
@onready var _card_picker: CardPickerScript = $CardPicker

# ── State ──────────────────────────────────────────────────────────────────────

enum _ServiceMode { REMOVE, UPGRADE }
var _service_mode: _ServiceMode = _ServiceMode.REMOVE

var _service_remove_button: Button  = null
var _service_upgrade_button: Button = null

## Tracks unsold card slots so gold refreshes can update their buy button state.
## Each entry: { button: Button, price: int, sold: bool }
var _card_slot_data: Array[Dictionary] = []

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_leave_button.pressed.connect(func() -> void: room_completed.emit())
	_card_picker.card_chosen.connect(_on_service_card_chosen)
	_build_shop()

# ── Shop builder ───────────────────────────────────────────────────────────────

func _build_shop() -> void:
	_refresh_gold()
	_build_card_display()
	_add_section_divider()
	_build_consumable_section()
	_add_section_divider()
	_build_gear_section()
	_add_section_divider()
	_build_services_section()

func _refresh_gold() -> void:
	var run: RunSaveData = RunState.active_run
	if run == null:
		return
	_gold_display.text = "Gold: %d" % run.gold
	for slot_info: Dictionary in _card_slot_data:
		if not slot_info["sold"]:
			var button: Button = slot_info["button"] as Button
			button.disabled = run.gold < slot_info["price"]

func _add_section_header(title: String) -> void:
	var header: Label = Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", COLOR_SECTION)
	_shop_list.add_child(header)

func _add_section_divider() -> void:
	var top_space: Control = Control.new()
	top_space.custom_minimum_size = Vector2(0, 4)
	_shop_list.add_child(top_space)
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_color_override("color", Color(0.50, 0.38, 0.14, 0.30))
	_shop_list.add_child(sep)
	var bottom_space: Control = Control.new()
	bottom_space.custom_minimum_size = Vector2(0, 4)
	_shop_list.add_child(bottom_space)

# ── Card display ───────────────────────────────────────────────────────────────

func _build_card_display() -> void:
	var player_class: String = ""
	if RunState.active_player != null:
		player_class = RunState.active_player.character_class

	var class_cards: Array[CardData] = []
	var neutral_cards: Array[CardData] = []
	_scan_card_pool(CARDS_DATA_PATH, player_class, class_cards, neutral_cards)
	class_cards.shuffle()
	neutral_cards.shuffle()

	var offered: Array[CardData] = []
	var neutral_take: int = mini(CARDS_NEUTRAL_MAX, neutral_cards.size())
	for i: int in neutral_take:
		offered.append(neutral_cards[i])
	var class_take: int = mini(CARDS_TOTAL_COUNT - offered.size(), class_cards.size())
	for i: int in class_take:
		offered.append(class_cards[i])
	offered.shuffle()

	for card: CardData in offered:
		_card_row.add_child(_build_card_slot(card))

func _scan_card_pool(
		dir_path: String,
		player_class_string: String,
		class_cards: Array[CardData],
		neutral_cards: Array[CardData]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			_scan_card_pool(dir_path + "/" + entry, player_class_string, class_cards, neutral_cards)
		elif entry.ends_with(".tres"):
			var resource: Resource = load(dir_path + "/" + entry)
			if resource is CardData:
				var card: CardData = resource as CardData
				if card.in_reward_pool and not card.is_token:
					if card.card_class == CardData.CardClass.NEUTRAL:
						neutral_cards.append(card)
					elif _is_class_match(card, player_class_string):
						class_cards.append(card)
		entry = dir.get_next()
	dir.list_dir_end()

func _is_class_match(card: CardData, player_class_string: String) -> bool:
	match card.card_class:
		CardData.CardClass.CLERIC:
			return player_class_string == "cleric"
	return false

func _build_card_slot(card: CardData) -> Control:
	var run: RunSaveData = RunState.active_run
	var price: int = CARD_PRICES.get(card.base_rarity, 50)
	var can_afford: bool = run != null and run.gold >= price

	var slot: VBoxContainer = VBoxContainer.new()
	slot.add_theme_constant_override("separation", 6)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var card_node: Card = CARD_SCENE.instantiate() as Card
	card_node.data = card
	card_node.custom_minimum_size = Card.SIZE
	card_node.mouse_filter = Control.MOUSE_FILTER_PASS
	card_node.pivot_offset = Vector2(Card.SIZE.x * 0.5, Card.SIZE.y * 0.5)
	slot.add_child(card_node)

	card_node.mouse_entered.connect(func() -> void:
		var tween: Tween = card_node.create_tween()
		tween.tween_property(card_node, "scale", CARD_HOVER_SCALE, 0.15) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK))
	card_node.mouse_exited.connect(func() -> void:
		var tween: Tween = card_node.create_tween()
		tween.tween_property(card_node, "scale", Vector2.ONE, 0.12) \
				.set_ease(Tween.EASE_OUT))

	var price_label: Label = Label.new()
	price_label.text = "%dg" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 14)
	price_label.add_theme_color_override("font_color", COLOR_PRICE)
	slot.add_child(price_label)

	var buy_button: Button = Button.new()
	buy_button.text = "Buy"
	buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_button.disabled = not can_afford
	slot.add_child(buy_button)

	var slot_info: Dictionary = {"button": buy_button, "price": price, "sold": false}
	_card_slot_data.append(slot_info)

	buy_button.pressed.connect(func() -> void:
		_buy_card(card, price, card_node, buy_button, price_label, slot_info))

	return slot

func _buy_card(
		card: CardData,
		price: int,
		card_node: Card,
		buy_button: Button,
		price_label: Label,
		slot_info: Dictionary) -> void:
	var run: RunSaveData = RunState.active_run
	if run == null or run.gold < price:
		return
	run.gold -= price
	run.deck_card_paths.append(card.resource_path)
	run.deck_card_upgrades.append(false)
	SaveManager.save()

	slot_info["sold"] = true
	buy_button.text = "Sold"
	buy_button.disabled = true
	price_label.add_theme_color_override("font_color", COLOR_SOLD)
	card_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_node.modulate = Color(0.50, 0.50, 0.50, 0.65)

	_refresh_gold()
	_refresh_service_buttons()

# ── Consumables ────────────────────────────────────────────────────────────────

func _build_consumable_section() -> void:
	_add_section_header("— ITEMS —")

	var consumables: Array[ConsumableData] = _load_consumables()
	consumables.shuffle()
	var count: int = mini(CONSUMABLES_COUNT, consumables.size())

	if count == 0:
		_shop_list.add_child(_make_empty_label("No items available."))
	else:
		for i: int in count:
			_shop_list.add_child(_build_consumable_row(consumables[i]))

func _load_consumables() -> Array[ConsumableData]:
	var result: Array[ConsumableData] = []
	var dir: DirAccess = DirAccess.open(CONSUMABLES_DATA_PATH)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry.ends_with(".tres"):
			var resource: Resource = load(CONSUMABLES_DATA_PATH + "/" + entry)
			if resource is ConsumableData:
				result.append(resource as ConsumableData)
		entry = dir.get_next()
	dir.list_dir_end()
	return result

func _build_consumable_row(consumable: ConsumableData) -> Control:
	var run: RunSaveData = RunState.active_run
	var belt_full: bool  = run != null and run.consumables.size() >= 3
	var can_afford: bool = run != null and run.gold >= CONSUMABLE_PRICE

	var row: PanelContainer = PanelContainer.new()
	row.add_theme_stylebox_override("panel", _make_row_style(false))

	var content: HBoxContainer = HBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	row.add_child(content)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	content.add_child(info)

	var name_label: Label = Label.new()
	name_label.text = consumable.item_name
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", COLOR_NAME)
	info.add_child(name_label)

	var desc_label: Label = Label.new()
	desc_label.text = consumable.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", COLOR_SUB)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_label)

	var price_label: Label = Label.new()
	price_label.text = "%dg" % CONSUMABLE_PRICE
	price_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_label.add_theme_font_size_override("font_size", 13)
	price_label.add_theme_color_override("font_color", COLOR_PRICE)
	content.add_child(price_label)

	var buy_button: Button = Button.new()
	buy_button.custom_minimum_size = Vector2(64, 0)
	buy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if belt_full:
		buy_button.text = "Full"
		buy_button.disabled = true
	else:
		buy_button.text = "Buy"
		buy_button.disabled = not can_afford
	content.add_child(buy_button)

	buy_button.pressed.connect(func() -> void:
		_buy_consumable(consumable, row, buy_button, price_label))

	return row

func _buy_consumable(
		consumable: ConsumableData,
		row: PanelContainer,
		buy_button: Button,
		price_label: Label) -> void:
	var run: RunSaveData = RunState.active_run
	if run == null or run.gold < CONSUMABLE_PRICE or run.consumables.size() >= 3:
		return
	run.gold -= CONSUMABLE_PRICE
	run.consumables.append(consumable)
	SaveManager.save()
	buy_button.text = "Sold"
	buy_button.disabled = true
	price_label.add_theme_color_override("font_color", COLOR_SOLD)
	row.add_theme_stylebox_override("panel", _make_row_style(true))
	_refresh_gold()

# ── Gear ───────────────────────────────────────────────────────────────────────

func _build_gear_section() -> void:
	_add_section_header("— EQUIPMENT —")
	_shop_list.add_child(_make_empty_label("No equipment available."))

# ── Services ───────────────────────────────────────────────────────────────────

func _build_services_section() -> void:
	_add_section_header("— SERVICES —")

	_service_remove_button = Button.new()
	_service_remove_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_service_remove_button.pressed.connect(_on_remove_service_pressed)
	_shop_list.add_child(_service_remove_button)

	_service_upgrade_button = Button.new()
	_service_upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_service_upgrade_button.pressed.connect(_on_upgrade_service_pressed)
	_shop_list.add_child(_service_upgrade_button)

	_refresh_service_buttons()

func _refresh_service_buttons() -> void:
	var run: RunSaveData = RunState.active_run
	if run == null:
		return

	if _service_remove_button != null:
		var can_afford: bool = run.gold >= SERVICE_REMOVE_PRICE
		var deck_ok: bool    = run.deck_card_paths.size() > 1
		_service_remove_button.disabled = not (can_afford and deck_ok)
		if not can_afford:
			_service_remove_button.text = "Remove a Card  — %dg  (have %dg)" % [SERVICE_REMOVE_PRICE, run.gold]
		elif not deck_ok:
			_service_remove_button.text = "Remove a Card  — %dg  (deck too small)" % SERVICE_REMOVE_PRICE
		else:
			_service_remove_button.text = "Remove a Card  — %dg" % SERVICE_REMOVE_PRICE

	if _service_upgrade_button != null:
		var can_afford: bool = run.gold >= SERVICE_UPGRADE_PRICE
		var has_card: bool   = _has_upgradeable_card(run)
		_service_upgrade_button.disabled = not (can_afford and has_card)
		if not can_afford:
			_service_upgrade_button.text = "Upgrade a Card  — %dg  (have %dg)" % [SERVICE_UPGRADE_PRICE, run.gold]
		elif not has_card:
			_service_upgrade_button.text = "Upgrade a Card  — %dg  (no cards to upgrade)" % SERVICE_UPGRADE_PRICE
		else:
			_service_upgrade_button.text = "Upgrade a Card  — %dg" % SERVICE_UPGRADE_PRICE

func _has_upgradeable_card(run: RunSaveData) -> bool:
	for i: int in run.deck_card_paths.size():
		var is_upgraded: bool = i < run.deck_card_upgrades.size() and run.deck_card_upgrades[i]
		if not is_upgraded:
			return true
	return false

func _on_remove_service_pressed() -> void:
	var run: RunSaveData = RunState.active_run
	if run == null or run.gold < SERVICE_REMOVE_PRICE:
		return
	var cards: Array[CardData] = []
	for path: String in run.deck_card_paths:
		var card: CardData = load(path) as CardData
		if card != null:
			cards.append(card)
	if cards.is_empty():
		return
	_service_mode = _ServiceMode.REMOVE
	_card_picker.open("Choose a card to remove  (%dg)" % SERVICE_REMOVE_PRICE, cards)

func _on_upgrade_service_pressed() -> void:
	var run: RunSaveData = RunState.active_run
	if run == null or run.gold < SERVICE_UPGRADE_PRICE:
		return
	var cards: Array[CardData] = []
	for i: int in run.deck_card_paths.size():
		var is_upgraded: bool = i < run.deck_card_upgrades.size() and run.deck_card_upgrades[i]
		if not is_upgraded:
			var card: CardData = load(run.deck_card_paths[i]) as CardData
			if card != null:
				cards.append(card)
	if cards.is_empty():
		return
	_service_mode = _ServiceMode.UPGRADE
	_card_picker.open("Choose a card to upgrade  (%dg)" % SERVICE_UPGRADE_PRICE, cards)

func _on_service_card_chosen(card: CardData) -> void:
	var run: RunSaveData = RunState.active_run
	if run == null:
		return
	match _service_mode:
		_ServiceMode.REMOVE:
			if run.gold < SERVICE_REMOVE_PRICE:
				return
			var index: int = run.deck_card_paths.find(card.resource_path)
			if index >= 0:
				run.deck_card_paths.remove_at(index)
				if index < run.deck_card_upgrades.size():
					run.deck_card_upgrades.remove_at(index)
			run.gold -= SERVICE_REMOVE_PRICE
		_ServiceMode.UPGRADE:
			if run.gold < SERVICE_UPGRADE_PRICE:
				return
			for i: int in run.deck_card_paths.size():
				if run.deck_card_paths[i] == card.resource_path:
					var already_upgraded: bool = i < run.deck_card_upgrades.size() and run.deck_card_upgrades[i]
					if not already_upgraded:
						run.deck_card_upgrades[i] = true
						break
			run.gold -= SERVICE_UPGRADE_PRICE
	SaveManager.save()
	_refresh_gold()
	_refresh_service_buttons()

# ── Helpers ────────────────────────────────────────────────────────────────────

func _make_row_style(sold: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if sold:
		style.bg_color     = Color(0.07, 0.05, 0.10, 0.55)
		style.border_color = Color(0.25, 0.18, 0.28, 0.35)
	else:
		style.bg_color     = Color(0.11, 0.07, 0.18, 1.0)
		style.border_color = Color(0.52, 0.40, 0.14, 0.70)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left   = 10.0
	style.content_margin_right  = 14.0
	style.content_margin_top    = 7.0
	style.content_margin_bottom = 7.0
	return style

func _make_empty_label(message: String) -> Label:
	var label: Label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", COLOR_SUB)
	return label
