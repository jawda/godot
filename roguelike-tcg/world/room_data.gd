class_name RoomData
extends Resource

## Runtime data for a single room in a generated dungeon floor.
## Created by the map generator — not a static .tres file.
## Stored in FloorMapData.rooms and saved as part of RunSaveData mid-run.

enum RoomType {
	START,      ## Entry point — no content, player begins here.
	COMBAT,     ## Standard enemy encounter. Rewards: XP, gold, card pick.
	ELITE,      ## Tougher single enemy. Rewards: XP, gold, gear pick.
	REST,       ## Rest site — heal, upgrade a card, swap gear, claim mastery.
	TREASURE,   ## Chest — gold, gear, or card removal.
	EVENT,      ## Narrative encounter with dialogue and a meaningful choice.
	SHOP,       ## Merchant — buy cards, gear, consumables; sell gear; remove/upgrade cards.
	BLACKSMITH, ## Upgrade one equipped gear item. Does not appear on floor 1.
	BOSS,       ## Floor boss — one enemy drawn from FloorData.boss_pool.
}

# ── Identity ───────────────────────────────────────────────────────────────────

@export var room_type: RoomType = RoomType.COMBAT:
	set(new_room_type):
		room_type = new_room_type
		emit_changed()

# ── Map layout ─────────────────────────────────────────────────────────────────

## Top-left corner of this room in map grid units.
@export var position: Vector2i = Vector2i.ZERO:
	set(new_position):
		position = new_position
		emit_changed()

## Width and height of this room in map grid units. Always rectangular.
@export var size: Vector2i = Vector2i(4, 4):
	set(new_size):
		size = new_size
		emit_changed()

# ── Graph ──────────────────────────────────────────────────────────────────────

## Indices of rooms this room connects to, into FloorMapData.rooms.
## The player can only move to connected rooms they haven't visited yet
## (or back to the previous room, if backtracking is allowed — not currently planned).
@export var connected_room_indices: Array[int] = []:
	set(new_connected_room_indices):
		connected_room_indices = new_connected_room_indices
		emit_changed()

# ── State ──────────────────────────────────────────────────────────────────────

## True once the player has entered this room.
@export var visited: bool = false:
	set(new_visited):
		visited = new_visited
		emit_changed()

## True once the room's content has been fully resolved —
## combat won, event choice made, chest opened, etc.
## Cleared rooms can still be re-entered but offer nothing new.
@export var cleared: bool = false:
	set(new_cleared):
		cleared = new_cleared
		emit_changed()

# ── Payload ────────────────────────────────────────────────────────────────────
# Set at generation time. Only the fields relevant to this room's type are populated.
# REST, TREASURE, SHOP, BLACKSMITH, and START rooms have no payload.

## COMBAT rooms: the enemies that spawn. 1–3 entries drawn from FloorData.combat_enemies.
@export var combat_enemies: Array[EnemyData] = []:
	set(new_combat_enemies):
		combat_enemies = new_combat_enemies
		emit_changed()

## ELITE rooms: the single elite enemy that spawns.
@export var elite_enemy: EnemyData = null:
	set(new_elite_enemy):
		elite_enemy = new_elite_enemy
		emit_changed()

## BOSS rooms: the boss drawn from FloorData.boss_pool.
@export var boss_enemy: EnemyData = null:
	set(new_boss_enemy):
		boss_enemy = new_boss_enemy
		emit_changed()

## EVENT rooms: the event to run when the player enters.
@export var event: EventData = null:
	set(new_event):
		event = new_event
		emit_changed()
