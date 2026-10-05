class_name State
extends Node

## Base class for a character state (idle, walk, attack, …).
##
## The state machine sets `character` and `state_machine` on init. The process /
## physics / handle_input callbacks return the NEXT state to switch to, or null
## to stay in the current one — the same pattern used across the project.

var character: Character
var state_machine: CharacterStateMachine

## Called once when the state machine initializes, before any state is entered.
func init() -> void:
	pass

## Called when this state becomes active.
func enter() -> void:
	pass

## Called when leaving this state.
func exit() -> void:
	pass

## Per-frame update (animation). Return the next state, or null to stay.
func process(_delta: float) -> State:
	return null

## Per-physics-tick update (movement). Return the next state, or null to stay.
func physics(_delta: float) -> State:
	return null

## Input handling. Return the next state, or null to stay.
func handle_input(_event: InputEvent) -> State:
	return null
