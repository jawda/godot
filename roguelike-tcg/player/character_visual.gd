class_name CharacterVisual
extends Node2D

# ── States ─────────────────────────────────────────────────────────────────────

enum State {
	IDLE,
	ATTACKING,  ## Player is performing an attack
	HIT,        ## Player's attack connects — enemy reacts (not the player)
	DAMAGED,    ## Player is taking damage
	DEAD,
}

# ── Signals ────────────────────────────────────────────────────────────────────

## Emitted when the attack animation finishes. Combat system listens to this
## before resolving damage so the hit visually lands at the right moment.
signal attack_finished

## Emitted when the hit animation finishes.
signal hit_finished

## Emitted when a single damaged animation finishes. If multiple damage instances
## were queued, this fires after each one — not just the last.
signal damaged_finished

## Emitted when the death animation finishes. Combat system listens to this
## before transitioning to the post-combat screen.
signal death_finished

# ── Node references ────────────────────────────────────────────────────────────

@onready var _sprite: AnimatedSprite2D = $Sprite

# ── Internal state ─────────────────────────────────────────────────────────────

var _current_state: State = State.IDLE

## Counts how many additional damage hits arrived while the damaged animation
## was already playing. Each queued hit plays the animation once more in sequence.
var _damaged_queue: int = 0

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_sprite.animation_finished.connect(_on_animation_finished)
	_transition_to(State.IDLE)

# ── Public API ─────────────────────────────────────────────────────────────────

## Plays the attack animation. Emits attack_finished when done and returns to idle.
func play_attack() -> void:
	_transition_to(State.ATTACKING)

## Plays the hit animation (player's strike connects). Emits hit_finished when done.
func play_hit() -> void:
	_transition_to(State.HIT)

## Plays the damaged animation (player takes a hit).
## If the animation is already playing, the request is queued and plays
## immediately after the current one finishes — so every hit gets its own animation.
func play_damaged() -> void:
	if _current_state == State.DAMAGED:
		_damaged_queue += 1
		return
	_transition_to(State.DAMAGED)

## Plays the death animation. Emits death_finished when done. Does not return to idle.
## Clears any pending damaged queue since the character is dead.
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
			_sprite.play("idle")
		State.ATTACKING:
			_sprite.play("attack")
		State.HIT:
			_sprite.play("hit")
		State.DAMAGED:
			_sprite.play("damaged")
		State.DEAD:
			_damaged_queue = 0
			_sprite.play("death")

func _on_animation_finished() -> void:
	match _current_state:
		State.ATTACKING:
			attack_finished.emit()
			_transition_to(State.IDLE)
		State.HIT:
			hit_finished.emit()
			_transition_to(State.IDLE)
		State.DAMAGED:
			damaged_finished.emit()
			if _damaged_queue > 0:
				_damaged_queue -= 1
				_transition_to(State.DAMAGED)
			else:
				_transition_to(State.IDLE)
		State.DEAD:
			death_finished.emit()
			# Stay in DEAD — no automatic transition.
