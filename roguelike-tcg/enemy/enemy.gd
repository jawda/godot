class_name Enemy
extends VBoxContainer

## Emitted when the enemy's HP reaches zero after damage is applied.
signal died

## Emitted when an HP threshold is crossed and the enemy enters a new phase.
signal phase_changed(phase: EnemyPhase)

## Emitted when the player clicks this enemy (used for targeting).
signal clicked(enemy: Enemy)

# ── Data ───────────────────────────────────────────────────────────────────────

@export var data: EnemyData

# ── Runtime state ──────────────────────────────────────────────────────────────

var current_health: int = 0
var current_block: int = 0
var took_damage_last_turn: bool = false

## Runtime attack/block base — start from data values, modified by BUFF_SELF/BUFF_ALLIES actions.
var combat_attack: int = 0
var combat_block_base: int = 0
## Active status effects — key: status name, value: stack count.
var statuses: Dictionary = {}

var _action_index: int = 0
var _current_phase: EnemyPhase = null

# ── Node references ────────────────────────────────────────────────────────────

@onready var _intent_label: Label               = $IntentDisplay/IntentLabel
@onready var _name_label: Label                 = $NameLabel
@onready var _sprite: AnimatedSprite2D          = $SpriteContainer/Sprite
@onready var _portrait: TextureRect             = $SpriteContainer/Portrait
@onready var _health_bar: ProgressBar           = $HealthBar
@onready var _health_label: Label               = $HealthLabel
@onready var _block_display: HBoxContainer      = $StatusRow/BlockDisplay
@onready var _block_label: Label                = $StatusRow/BlockDisplay/BlockLabel
@onready var _status_container: HBoxContainer   = $StatusRow/StatusContainer

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	if data:
		setup(data)

# ── Setup ──────────────────────────────────────────────────────────────────────

## Initialises the enemy from an EnemyData resource.
## Call this before the first player turn if not setting data via the inspector.
func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	current_health = data.max_health
	current_block = 0
	combat_attack = data.base_attack
	combat_block_base = data.base_block
	statuses.clear()
	_action_index = 0
	_current_phase = null
	took_damage_last_turn = false

	_name_label.text = data.enemy_name
	_health_bar.max_value = data.max_health

	if data.sprite_frames:
		_sprite.sprite_frames = data.sprite_frames
		_sprite.visible = true
		_portrait.visible = false
		_sprite.play("idle")
	elif data.portrait_texture:
		_portrait.texture = data.portrait_texture
		_portrait.visible = true
		_sprite.visible = false
	else:
		_sprite.visible = false
		_portrait.visible = false

	_update_display()
	_update_intent()

# ── Combat interface ───────────────────────────────────────────────────────────

## Returns the action this enemy will perform on its next turn.
## Call before resolving enemy turn, then call advance_action() after.
func get_current_action() -> EnemyAction:
	var pool: Array[EnemyAction] = _active_action_pool()
	if pool.is_empty():
		return null
	if data.ai_pattern == EnemyData.AiPattern.SEQUENTIAL:
		return pool[_action_index % pool.size()]
	return _pick_weighted(pool)

## Advances to the next action in the pool and refreshes the intent display.
## Call at the end of the enemy's turn after its action has resolved.
func advance_action() -> void:
	took_damage_last_turn = false
	if data.ai_pattern == EnemyData.AiPattern.SEQUENTIAL:
		var pool: Array[EnemyAction] = _active_action_pool()
		if not pool.is_empty():
			_action_index = (_action_index + 1) % pool.size()
	_update_intent()

## Applies damage to this enemy, absorbing through block first.
## Emits died if HP reaches zero.
func take_damage(amount: int) -> void:
	var absorbed: int = mini(current_block, amount)
	current_block -= absorbed
	current_health -= (amount - absorbed)
	current_health = maxi(current_health, 0)
	took_damage_last_turn = true
	_check_phase_transition()
	_update_display()
	if is_dead():
		died.emit()

## Adds block to this enemy.
func gain_block(amount: int) -> void:
	current_block += amount
	_update_display()

func is_dead() -> bool:
	return current_health <= 0

## Returns true if the enemy has the given tag (e.g. "undead", "beast").
func has_tag(tag: String) -> bool:
	return data != null and data.tags.has(tag)

## Returns the number of stacks of the given status (0 if not present).
func get_status(status_name: String) -> int:
	return statuses.get(status_name, 0)

## Adds stacks to the given status and refreshes the display.
func apply_status(status_name: String, stacks: int) -> void:
	statuses[status_name] = statuses.get(status_name, 0) + stacks
	_update_display()

## Modifies a runtime combat stat. stat should be "attack" or "block".
func apply_buff(stat: String, amount: int) -> void:
	match stat:
		"attack": combat_attack += amount
		"block":  combat_block_base += amount

## Removes all current block from this enemy.
func clear_block() -> void:
	current_block = 0
	_update_display()

# ── Input ──────────────────────────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(self)
		accept_event()

# ── AI ─────────────────────────────────────────────────────────────────────────

func _active_action_pool() -> Array[EnemyAction]:
	if _current_phase != null:
		return _current_phase.actions
	return data.actions

func _check_phase_transition() -> void:
	if data.phases.is_empty():
		return
	var hp_fraction: float = float(current_health) / float(data.max_health)
	for phase: EnemyPhase in data.phases:
		if hp_fraction <= phase.hp_threshold and phase != _current_phase:
			_current_phase = phase
			_action_index = 0
			phase_changed.emit(phase)
			_update_intent()
			return

func _pick_weighted(pool: Array[EnemyAction]) -> EnemyAction:
	var total_weight: int = 0
	for action: EnemyAction in pool:
		total_weight += _effective_weight(action)
	if total_weight <= 0:
		return pool[randi() % pool.size()]
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for action: EnemyAction in pool:
		cumulative += _effective_weight(action)
		if roll < cumulative:
			return action
	return pool[-1]

func _effective_weight(action: EnemyAction) -> int:
	var weight: int = action.base_weight
	for modifier: ActionWeightModifier in action.weight_modifiers:
		if _is_condition_met(modifier):
			weight += modifier.weight_bonus
	return maxi(weight, 0)

func _is_condition_met(modifier: ActionWeightModifier) -> bool:
	match modifier.condition:
		ActionWeightModifier.Condition.NONE:
			return true
		ActionWeightModifier.Condition.HP_BELOW_THRESHOLD:
			return float(current_health) / float(data.max_health) <= modifier.threshold
		ActionWeightModifier.Condition.HP_ABOVE_THRESHOLD:
			return float(current_health) / float(data.max_health) >= modifier.threshold
		ActionWeightModifier.Condition.TOOK_DAMAGE_LAST_TURN:
			return took_damage_last_turn
		ActionWeightModifier.Condition.HAS_BLOCK:
			return current_block > 0
		ActionWeightModifier.Condition.PLAYER_HP_BELOW_THRESHOLD, \
		ActionWeightModifier.Condition.ALLY_PRESENT, \
		ActionWeightModifier.Condition.ALLY_DIED:
			## These conditions require context from the combat manager.
			## The combat system should evaluate and cache these before
			## calling get_current_action() each turn.
			return false
	return false

# ── Display ────────────────────────────────────────────────────────────────────

func _update_display() -> void:
	_health_bar.value = current_health
	_health_label.text = "%d / %d" % [current_health, data.max_health]
	_block_display.visible = current_block > 0
	_block_label.text = str(current_block)
	for child: Node in _status_container.get_children():
		child.queue_free()
	for status_name: String in statuses:
		if statuses[status_name] <= 0:
			continue
		var status_label: Label = Label.new()
		status_label.text = "%s: %d" % [status_name.capitalize(), statuses[status_name]]
		_status_container.add_child(status_label)

func _update_intent() -> void:
	var action: EnemyAction = get_current_action()
	_intent_label.text = action.intent_description if action else ""
