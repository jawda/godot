class_name CharacterVisual
extends Node2D

# ── States ─────────────────────────────────────────────────────────────────────

enum State {
	IDLE,
	ATTACKING,  ## Player is performing an attack
	HIT,        ## Player's attack connects — weapon effect plays
	DAMAGED,    ## Player is taking damage
	DEAD,
}

# ── Signals ────────────────────────────────────────────────────────────────────

## Emitted when the attack animation finishes.
signal attack_finished
## Emitted when the hit animation finishes.
signal hit_finished
## Emitted when a single damaged animation finishes.
signal damaged_finished
## Emitted when the death animation finishes.
signal death_finished

# ── Node references ────────────────────────────────────────────────────────────

@onready var _sprite: Sprite2D            = $Sprite
@onready var _blast_sprite: Sprite2D      = $BlastSprite
@onready var _anim_player: AnimationPlayer = $AnimationPlayer

# ── Internal state ─────────────────────────────────────────────────────────────

var _current_state: State = State.IDLE

## Counts how many additional damage hits arrived while the damaged animation
## was already playing. Each queued hit plays the animation once more in sequence.
var _damaged_queue: int = 0

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_anim_player.animation_finished.connect(_on_animation_finished)
	_transition_to(State.IDLE)

# ── Public API ─────────────────────────────────────────────────────────────────

## Plays the attack animation. Emits attack_finished when done and returns to idle.
func play_attack() -> void:
	_transition_to(State.ATTACKING)

## Plays the hit animation (weapon effect on connect). Emits hit_finished when done.
func play_hit() -> void:
	_transition_to(State.HIT)

## Plays the damaged animation. Queues additional hits if already playing.
func play_damaged() -> void:
	if _current_state == State.DAMAGED:
		_damaged_queue += 1
		return
	_transition_to(State.DAMAGED)

## Plays the death animation. Emits death_finished when done. Terminal state.
func play_death() -> void:
	_transition_to(State.DEAD)

func is_dead() -> bool:
	return _current_state == State.DEAD

# ── State machine ──────────────────────────────────────────────────────────────

func _transition_to(new_state: State) -> void:
	# Dead is a terminal state — nothing transitions out of it.
	if _current_state == State.DEAD:
		return

	_current_state = new_state

	match _current_state:
		State.IDLE:
			_anim_player.play("idle")
		State.ATTACKING:
			_anim_player.play("attack")
		State.HIT:
			_anim_player.play("hit")
		State.DAMAGED:
			_anim_player.play("damaged")
		State.DEAD:
			_damaged_queue = 0
			_anim_player.play("death")

func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"attack":
			attack_finished.emit()
			_transition_to(State.IDLE)
		"hit":
			hit_finished.emit()
			_transition_to(State.IDLE)
		"damaged":
			damaged_finished.emit()
			if _damaged_queue > 0:
				_damaged_queue -= 1
				_transition_to(State.DAMAGED)
			else:
				_transition_to(State.IDLE)
		"death":
			death_finished.emit()
			# Stay in DEAD — no automatic transition.
