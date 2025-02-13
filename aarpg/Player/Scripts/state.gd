class_name State extends Node

## Store reference to player that the state belongs to
static var player: Player

func _ready():
	pass
	

## What happens when the player enters this state?
func Enter() -> void:
	pass

## What happens when the player exits this State?
func Exit() -> void:
	pass
	

## What happens during the _process update in this state?
func Process( _delta: float ) -> State:
	return null

## What happens during the _physics_process update in this State?
func Physics( _delta : float) -> State:
	return null
	

## what happens with input events in this State?
func HandleInput( _event: InputEvent ) -> State:
	return null
