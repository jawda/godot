#need to add icon from itch.io page here
#@icon("res://player/states/state.svg")
class_name PlayerState extends Node

var player : Player
var next_state : PlayerState

#region /// state references
#refrence to all other states

#endregion

# What happens when this state is initialized
func init() -> void:
	
	pass
	
# What happens when we enter this state	
func enter() -> void:
	
	pass
	
#what happens when we exit this state
func exit() -> void:
	
	pass

#  What happens when an input is pressed or released?
func handle_input( _event : InputEvent ) -> PlayerState:
	
	return next_state
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(_delta: float) -> PlayerState:

	return next_state

func physics_process(_delta: float) -> PlayerState:
	
	return next_state
