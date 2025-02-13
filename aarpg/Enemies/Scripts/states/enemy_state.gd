class_name EnemyState extends Node


## Stores a reference to the enemy that this state belongs to
var enemy : Enemy
var state_machine : EnemyStateMachine

## Initialize state
func init() -> void:
	pass

## Enter the state
func enter() -> void:
	pass
	
## Exit the state
func exit() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(_delta: float) -> EnemyState:
	return null

func physics( _delta : float) -> EnemyState:
	return null 
