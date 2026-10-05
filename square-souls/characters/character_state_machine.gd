class_name CharacterStateMachine
extends Node

## Drives the active State. Child State nodes are collected on init; process /
## physics / input are delegated to the current state, and whatever a state
## returns becomes the next state.
##
## Only runs at runtime (not @tool), so states never animate in the editor.

var states: Array[State] = []
var current_state: State = null
var previous_state: State = null

var _character: Character = null

func initialize(owner_character: Character) -> void:
	_character = owner_character
	states.clear()
	for child: Node in get_children():
		if child is State:
			var state: State = child as State
			state.character = owner_character
			state.state_machine = self
			states.append(state)
	for state: State in states:
		state.init()
	if not states.is_empty():
		change_state(states[0])

func _process(delta: float) -> void:
	if current_state == null:
		return
	# Reset the skeleton to rest each frame; the active state then poses the
	# bones it cares about on top (so nothing freezes when states change).
	_character.reset_pose()
	change_state(current_state.process(delta))

func _physics_process(delta: float) -> void:
	if current_state != null:
		change_state(current_state.physics(delta))

func _unhandled_input(event: InputEvent) -> void:
	if current_state != null:
		change_state(current_state.handle_input(event))

func change_state(new_state: State) -> void:
	if new_state == null or new_state == current_state:
		return
	if current_state != null:
		current_state.exit()
	previous_state = current_state
	current_state = new_state
	current_state.enter()
