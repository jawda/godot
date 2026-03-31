@tool
class_name EnemyAction
extends Resource

enum ActionType {
	ATTACK,       ## Deal damage to the player
	BLOCK,        ## Gain block this turn
	APPLY_STATUS, ## Apply a status effect to the target
	BUFF_SELF,    ## Temporarily increase own stats for the rest of combat
	BUFF_ALLIES,  ## Apply a buff to all other enemies in the current encounter
	SPECIAL,      ## Named special ability resolved by the combat system via param
}

enum ActionTarget {
	PLAYER,     ## Targets the player
	SELF,       ## Targets this enemy
	ALL_ALLIES, ## Targets all other enemies in the encounter (excludes self)
}

@export var action_type: ActionType = ActionType.ATTACK:
	set(new_action_type):
		action_type = new_action_type
		emit_changed()

## The magnitude of the action. Meaning depends on action_type:
## ATTACK: added to the enemy's base_attack for total damage dealt.
## BLOCK: added to the enemy's base_block for total block gained.
## APPLY_STATUS: number of stacks applied.
## BUFF_SELF / BUFF_ALLIES: amount the target stat is increased.
@export var value: int = 0:
	set(new_value):
		value = new_value
		emit_changed()

## What the player sees telegraphed as this enemy's intent before it resolves.
## e.g. "Raises its claws — preparing to strike for 8 damage."
@export_multiline var intent_description: String = "":
	set(new_intent_description):
		intent_description = new_intent_description
		emit_changed()

@export var target: ActionTarget = ActionTarget.PLAYER:
	set(new_target):
		target = new_target
		emit_changed()

## Context-sensitive string parameter:
## APPLY_STATUS — the status to apply (e.g. "vulnerable", "weak", "burn").
## BUFF_SELF / BUFF_ALLIES — the stat to modify (e.g. "attack", "block").
## SPECIAL — the ability identifier the combat system looks up to resolve.
@export var param: String = "":
	set(new_param):
		param = new_param
		emit_changed()

## Baseline likelihood this action is chosen when ai_pattern is WEIGHTED.
## The combat system adds active weight_modifier bonuses to this each turn before selecting.
@export var base_weight: int = 1:
	set(new_base_weight):
		base_weight = new_base_weight
		emit_changed()

## Conditional bonuses applied on top of base_weight each turn.
## Effective weight = base_weight + sum of all active modifier bonuses, minimum 0.
@export var weight_modifiers: Array[ActionWeightModifier] = []:
	set(new_weight_modifiers):
		weight_modifiers = new_weight_modifiers
		emit_changed()
