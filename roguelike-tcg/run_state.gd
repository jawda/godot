# AutoLoad singleton — no class_name (Godot forbids it on AutoLoad scripts).
# Register as "RunState" in Project Settings → Autoload → add res://run_state.gd as "RunState".
extends Node

## Ordered list of FloorData resources defining the floor sequence for the current run.
## Index 0 = floor 1, index 1 = floor 2, etc.
var floor_sequence: Array[FloorData] = []

## The PlayerData for the character being played this run.
var active_player: PlayerData = null

## Live save state for the in-progress run. Null when no run is active.
var active_run: RunSaveData = null

# ── Public API ─────────────────────────────────────────────────────────────────

## Initialise all run state and generate the first floor map.
## Call this from CharacterSelect before transitioning to FloorLoop.
func start_new_run(
		player: PlayerData,
		sequence: Array[FloorData],
		starting_max_hp: int) -> void:
	active_player = player
	floor_sequence = sequence

	var run: RunSaveData = RunSaveData.new()
	run.current_health = starting_max_hp
	run.current_max_health = starting_max_hp
	run.current_floor = 1
	run.floor_map = FloorMapGenerator.generate(sequence[0])

	if player.starter_deck != null:
		for card: CardData in player.starter_deck.starter_cards:
			run.deck_card_paths.append(card.resource_path)
			run.deck_card_upgrades.append(false)

	active_run = run

## Returns the FloorData for the current floor, or null if the index is out of range.
func get_current_floor_data() -> FloorData:
	if active_run == null:
		return null
	var floor_index: int = active_run.current_floor - 1
	if floor_index < 0 or floor_index >= floor_sequence.size():
		return null
	return floor_sequence[floor_index]
