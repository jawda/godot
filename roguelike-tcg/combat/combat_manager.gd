class_name CombatManager
extends Node

## Manages the full turn cycle for one combat encounter:
## setup → player turn → enemy turn → repeat → victory/defeat

enum TurnState {
	IDLE,
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT,
}

# ── Signals ─────────────────────────────────────────────────────────────────────

## Emitted once at the very start of combat.
signal combat_started
## Emitted at the beginning of each player turn.
signal player_turn_began(energy: int, max_energy: int)
## Emitted when the enemy turn begins (after end_player_turn is called).
signal enemy_turn_began
## Emitted when all living enemies have resolved their actions for the turn.
signal enemy_turn_ended
## Emitted whenever the player's HP or block changes.
signal player_hp_changed(current: int, max_val: int)
signal player_block_changed(block: int)
## Emitted whenever the player's energy changes.
signal player_energy_changed(current: int, max_val: int)
## Emitted when a status is applied to any combatant.
signal status_applied(target_name: String, status: String, stacks: int)
## Emitted when an enemy is killed. Index is the position in the enemies array.
signal enemy_died(enemy_index: int)
## Emitted when combat ends. victory is true if all enemies are dead.
signal combat_ended(victory: bool)
## Emitted when an enemy action with type SPECIAL fires.
## The battlefield resolves the param string (e.g. "summon_skeleton") and calls add_enemy().
signal special_action_triggered(param: String)
## Emitted when the draw or discard pile count changes.
signal draw_pile_changed(count: int)
signal discard_pile_changed(count: int)
signal exile_pile_changed(count: int)
## Emitted when the player deals damage to an enemy (for attack animation).
signal player_attacked
## Emitted when the player takes damage from an enemy attack (for damage animation).
signal player_took_damage

# ── Constants ───────────────────────────────────────────────────────────────────

const INITIAL_HAND_SIZE: int = 5
## Seconds between consecutive enemy action resolutions.
const ENEMY_ACTION_DELAY: float = 0.6

# ── Dependencies (set via setup()) ──────────────────────────────────────────────

var _player: CombatPlayer = null
var _deck: Deck = null
var _hand: Hand = null
var _enemies: Array[Enemy] = []

# ── State ───────────────────────────────────────────────────────────────────────

var turn_state: TurnState = TurnState.IDLE
var _cards_played_this_turn: int = 0

## Power/Blessing effects installed this combat (Array[Dictionary] with "effect" and "card" keys).
var _active_powers: Array[Dictionary] = []

# ── Setup ───────────────────────────────────────────────────────────────────────

## Call before start_combat(). Provide the same Deck instance set on the Hand.
func setup(player_data: PlayerData, hand: Hand, deck: Deck, enemies: Array[Enemy],
		run_health: int = -1) -> void:
	_player = CombatPlayer.new()
	_player.setup(player_data, run_health)
	_hand = hand
	_deck = deck
	_enemies = enemies
	_active_powers.clear()
	_cards_played_this_turn = 0
	turn_state = TurnState.IDLE
	_hand.card_drawn.connect(_emit_deck_ui)

## Starts the combat: emits combat_started and begins the first player turn.
func start_combat() -> void:
	combat_started.emit()
	_emit_player_ui()
	_emit_deck_ui()
	_begin_player_turn()

# ── Player turn ─────────────────────────────────────────────────────────────────

func _begin_player_turn() -> void:
	turn_state = TurnState.PLAYER_TURN
	_cards_played_this_turn = 0

	# Block clears each turn (Slay the Spire style)
	_player.clear_block()
	_player.refill_energy()

	# Clear one-turn status flags before ticking DoTs
	_player.statuses.erase("double_heal")

	# Deal DoT damage before the turn starts, then decrement durations
	_apply_dot_damage()
	_player.tick_statuses()

	_emit_player_ui()

	_hand.draw_multiple(INITIAL_HAND_SIZE)

	# Fire TURN_START power triggers
	_fire_power_triggers(CardEffect.PowerTrigger.TURN_START, 0)

	player_turn_began.emit(_player.current_energy, _player.max_energy)

## Called by battlefield when the player presses End Turn.
func end_player_turn() -> void:
	if turn_state != TurnState.PLAYER_TURN:
		return
	turn_state = TurnState.ENEMY_TURN
	_hand.discard_all()
	_emit_deck_ui()
	_begin_enemy_turn()

## Registers a newly spawned enemy (e.g. from a summon action) into the active encounter.
## Call this after adding the Enemy node to the scene tree.
func add_enemy(enemy: Enemy) -> void:
	_enemies.append(enemy)

## Returns true if the player has enough energy to play this card right now.
func can_play(card_data: CardData) -> bool:
	if turn_state != TurnState.PLAYER_TURN:
		return false
	if _player.get_status("free_next_card") > 0:
		return true
	return _player.current_energy >= card_data.effective_cost

## Attempts to play a card. Returns false if the card cannot be played right now.
func play_card(card_data: CardData, target_enemy: Enemy) -> bool:
	if turn_state != TurnState.PLAYER_TURN:
		return false

	# Honour free_next_card status
	var actual_cost: int = card_data.effective_cost
	if _player.get_status("free_next_card") > 0:
		actual_cost = 0
		_player.statuses.erase("free_next_card")

	if not _player.spend_energy(actual_cost):
		return false

	for effect: CardEffect in card_data.effects:
		if effect.power_trigger != CardEffect.PowerTrigger.NONE:
			_active_powers.append({ "effect": effect, "card": card_data })
		else:
			_resolve_card_effect(effect, card_data, target_enemy, 0, true)

	if card_data.card_type == CardData.CardType.POWER:
		_hand.exile_specific_data(card_data)
	else:
		_hand.discard_specific_data(card_data)
	_cards_played_this_turn += 1

	_fire_power_triggers(CardEffect.PowerTrigger.ON_CARD_PLAYED, 0)
	_emit_player_ui()
	_emit_deck_ui()
	return true

# ── Effect resolution ───────────────────────────────────────────────────────────

func _resolve_card_effect(effect: CardEffect, card: CardData, target_enemy: Enemy,
		trigger_amount: int, fire_triggers: bool) -> void:
	var magnitude: int = _get_magnitude(effect, card, trigger_amount)

	match effect.effect_type:
		CardEffect.EffectType.DAMAGE:
			_deal_player_damage_to_enemy(effect, magnitude, target_enemy)

		CardEffect.EffectType.BLOCK:
			_player.gain_block(magnitude)
			player_block_changed.emit(_player.current_block)

		CardEffect.EffectType.DRAW:
			_hand.draw_multiple(magnitude, 0.1)

		CardEffect.EffectType.HEAL:
			var heal_amount: int = magnitude
			if _player.get_status("double_heal") > 0:
				heal_amount *= 2
			var healed: int = _player.heal(heal_amount)
			player_hp_changed.emit(_player.current_health, _player.max_health)
			if fire_triggers and healed > 0:
				_fire_power_triggers(CardEffect.PowerTrigger.ON_HEAL, healed)

		CardEffect.EffectType.APPLY_STATUS:
			_apply_status_effect(effect, magnitude, target_enemy)

		CardEffect.EffectType.STAT_UP:
			_apply_player_stat(effect.param, magnitude)

		CardEffect.EffectType.CLEAR_BLOCK:
			if effect.target == CardEffect.Target.SELF:
				_player.clear_block()
				player_block_changed.emit(_player.current_block)
			elif effect.target == CardEffect.Target.ENEMY and target_enemy != null:
				target_enemy.clear_block()
			elif effect.target == CardEffect.Target.ALL_ENEMIES:
				for enemy: Enemy in _living_enemies():
					enemy.clear_block()

		CardEffect.EffectType.GENERATE_TOKEN:
			if effect.token_data != null:
				match effect.token_destination:
					CardEffect.TokenDestination.HAND:
						_hand.add_card_to_hand(effect.token_data)
					CardEffect.TokenDestination.DRAW_PILE:
						_deck.add_card(effect.token_data)
					CardEffect.TokenDestination.DISCARD_PILE:
						_deck.discard_card(effect.token_data)
				_emit_deck_ui()

func _deal_player_damage_to_enemy(effect: CardEffect, base_magnitude: int,
		target_enemy: Enemy) -> void:
	if target_enemy == null or target_enemy.is_dead():
		return
	var damage: int = base_magnitude + _player.strength
	# Holy damage doubles against undead
	if effect.damage_type == CardEffect.DamageType.HOLY and target_enemy.has_tag("undead"):
		damage *= 2
	# Vulnerable: target takes 50% more damage
	if target_enemy.get_status("vulnerable") > 0:
		damage = roundi(damage * 1.5)
	# Weak: player deals 25% less damage
	if _player.get_status("weak") > 0:
		damage = roundi(damage * 0.75)
	player_attacked.emit()
	target_enemy.take_damage(damage)
	if target_enemy.is_dead():
		enemy_died.emit(_enemies.find(target_enemy))
		_check_victory()
	else:
		target_enemy.play_damaged()

func _apply_status_effect(effect: CardEffect, magnitude: int, target_enemy: Enemy) -> void:
	match effect.target:
		CardEffect.Target.SELF:
			_player.apply_status(effect.param, magnitude)
			status_applied.emit("Player", effect.param, magnitude)
		CardEffect.Target.ENEMY:
			if target_enemy != null:
				target_enemy.apply_status(effect.param, magnitude)
				status_applied.emit(target_enemy.data.enemy_name, effect.param, magnitude)
		CardEffect.Target.ALL_ENEMIES:
			for enemy: Enemy in _living_enemies():
				enemy.apply_status(effect.param, magnitude)

func _get_magnitude(effect: CardEffect, card: CardData, trigger_amount: int) -> int:
	match effect.value_source:
		CardEffect.ValueSource.FIXED:
			return effect.resolved_value(card.upgraded)
		CardEffect.ValueSource.CURRENT_HP:
			return _player.current_health
		CardEffect.ValueSource.CURRENT_BLOCK:
			return _player.current_block
		CardEffect.ValueSource.LIFE_GAINED_THIS_COMBAT:
			return _player.life_gained_this_combat
		CardEffect.ValueSource.TRIGGER_AMOUNT:
			return trigger_amount
	return 0

func _apply_player_stat(stat: String, amount: int) -> void:
	match stat:
		"strength":  _player.strength += amount
		"dexterity": _player.dexterity += amount
		"faith":     _player.faith += amount

# ── Power triggers ──────────────────────────────────────────────────────────────

## Fires all installed power effects that match the given trigger type.
## trigger_amount is passed through to TRIGGER_AMOUNT value sources (e.g. heal amount for ON_HEAL).
func _fire_power_triggers(trigger: CardEffect.PowerTrigger, trigger_amount: int) -> void:
	for entry: Dictionary in _active_powers:
		var effect: CardEffect = entry["effect"]
		var card: CardData = entry["card"]
		if effect.power_trigger == trigger:
			_resolve_card_effect(effect, card, _first_living_enemy(), trigger_amount, false)

# ── Enemy turn ──────────────────────────────────────────────────────────────────

func _begin_enemy_turn() -> void:
	enemy_turn_began.emit()
	_clear_enemy_block()
	_run_enemy_actions()

## Runs each living enemy's action in sequence with a delay between them.
## Called without await — resolves asynchronously in the background.
func _run_enemy_actions() -> void:
	for enemy: Enemy in _living_enemies():
		var action: EnemyAction = enemy.get_current_action()
		if action != null:
			_resolve_enemy_action(action, enemy)
		enemy.advance_action()
		if _player.is_dead():
			_check_defeat()
			return
		await get_tree().create_timer(ENEMY_ACTION_DELAY).timeout

	enemy_turn_ended.emit()
	if not _check_defeat():
		_begin_player_turn()

func _resolve_enemy_action(action: EnemyAction, enemy: Enemy) -> void:
	match action.action_type:
		EnemyAction.ActionType.ATTACK:
			enemy.play_attack()
			var damage: int = enemy.combat_attack + action.value
			# Vulnerable player takes 50% more damage
			if _player.get_status("vulnerable") > 0:
				damage = roundi(damage * 1.5)
			_player.take_damage(damage)
			player_hp_changed.emit(_player.current_health, _player.max_health)
			player_block_changed.emit(_player.current_block)
			player_took_damage.emit()

		EnemyAction.ActionType.BLOCK:
			enemy.gain_block(enemy.combat_block_base + action.value)

		EnemyAction.ActionType.APPLY_STATUS:
			if action.target == EnemyAction.ActionTarget.PLAYER:
				_player.apply_status(action.param, action.value)
				status_applied.emit("Player", action.param, action.value)
			elif action.target == EnemyAction.ActionTarget.SELF:
				enemy.apply_status(action.param, action.value)

		EnemyAction.ActionType.BUFF_SELF:
			enemy.apply_buff(action.param, action.value)

		EnemyAction.ActionType.BUFF_ALLIES:
			for ally: Enemy in _living_enemies():
				if ally != enemy:
					ally.apply_buff(action.param, action.value)

		EnemyAction.ActionType.SPECIAL:
			special_action_triggered.emit(action.param)

func _clear_enemy_block() -> void:
	for enemy: Enemy in _living_enemies():
		enemy.clear_block()

# ── Status ticking ──────────────────────────────────────────────────────────────

func _apply_dot_damage() -> void:
	var burn: int = _player.get_status("burn")
	if burn > 0:
		_player.take_damage(burn)
		player_hp_changed.emit(_player.current_health, _player.max_health)
	var bleed: int = _player.get_status("bleed")
	if bleed > 0:
		_player.take_damage(bleed)
		player_hp_changed.emit(_player.current_health, _player.max_health)

# ── Win / lose ──────────────────────────────────────────────────────────────────

func _check_victory() -> bool:
	if _living_enemies().is_empty():
		turn_state = TurnState.VICTORY
		combat_ended.emit(true)
		return true
	return false

func _check_defeat() -> bool:
	if _player.is_dead():
		turn_state = TurnState.DEFEAT
		combat_ended.emit(false)
		return true
	return false

# ── Helpers ─────────────────────────────────────────────────────────────────────

func _living_enemies() -> Array[Enemy]:
	var living: Array[Enemy] = []
	for enemy: Enemy in _enemies:
		if not enemy.is_dead():
			living.append(enemy)
	return living

func _first_living_enemy() -> Enemy:
	for enemy: Enemy in _enemies:
		if not enemy.is_dead():
			return enemy
	return null

func _emit_player_ui() -> void:
	player_hp_changed.emit(_player.current_health, _player.max_health)
	player_block_changed.emit(_player.current_block)
	player_energy_changed.emit(_player.current_energy, _player.max_energy)

func _emit_deck_ui() -> void:
	draw_pile_changed.emit(_deck.draw_pile_count())
	discard_pile_changed.emit(_deck.discard_pile_count())
	exile_pile_changed.emit(_deck.exile_pile_count())
