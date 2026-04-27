@tool
class_name EnemyData
extends Resource

enum Tier {
	MINION,    ## Standard encounters — simple patterns, lower health and damage
	COMMANDER, ## Stronger minions that can buff or command allies in the encounter
	ELITE,     ## Mini-boss tier — significantly more health, complex action sets
	BOSS,      ## Floor boss — special abilities, large health pool, phase changes
}

enum AiPattern {
	SEQUENTIAL, ## Cycles through the action pool in order, looping at the end
	WEIGHTED,   ## Picks based on each action's effective weight (base_weight + active modifier bonuses)
				## Equal base_weights with no modifiers produces uniform random behaviour
}

# ── Identity ───────────────────────────────────────────────────────────────────

@export_group("Identity")

@export var enemy_name: String = "Unknown Enemy":
	set(new_enemy_name):
		enemy_name = new_enemy_name
		emit_changed()

@export var tier: Tier = Tier.MINION:
	set(new_tier):
		tier = new_tier
		emit_changed()

@export_multiline var description: String = "":
	set(new_description):
		description = new_description
		emit_changed()

## Extended lore text shown in the compendium after the player has defeated this enemy at least once.
## description is shown on first encounter; compendium_lore unlocks on kill.
@export_multiline var compendium_lore: String = "":
	set(new_compendium_lore):
		compendium_lore = new_compendium_lore
		emit_changed()

## Tags that affect combat resolution.
## e.g. ["undead"] causes holy damage to deal double.
## e.g. ["beast"], ["demon"], ["human"] may interact with specific card effects.
@export var tags: Array[String] = []:
	set(new_tags):
		tags = new_tags
		emit_changed()

# ── Visuals ────────────────────────────────────────────────────────────────────

@export_group("Visuals")

## Portrait image used in the compendium and as a fallback in combat when no sprite sheet is set.
@export var portrait_texture: Texture2D:
	set(new_portrait_texture):
		portrait_texture = new_portrait_texture
		emit_changed()

## Sprite sheet loaded into the combat scene's AnimatedSprite2D at runtime.
## Expected animations: "idle", "attack", "hit", "death".
## Leave empty until art is ready — the combat scene will show a placeholder.
@export var sprite_frames: SpriteFrames:
	set(new_sprite_frames):
		sprite_frames = new_sprite_frames
		emit_changed()

## Scale applied to the AnimatedSprite2D when sprite_frames is set.
## Adjust per-enemy to fit the sprite container (160×140). Default is no scaling.
@export var visual_scale: Vector2 = Vector2.ONE:
	set(new_visual_scale):
		visual_scale = new_visual_scale
		emit_changed()

# ── Stats ──────────────────────────────────────────────────────────────────────

@export_group("Stats")

@export var max_health: int = 20:
	set(new_max_health):
		max_health = new_max_health
		emit_changed()

## Base damage applied to all ATTACK actions on top of the action's own value.
@export var base_attack: int = 5:
	set(new_base_attack):
		base_attack = new_base_attack
		emit_changed()

## Base block applied to all BLOCK actions on top of the action's own value.
@export var base_block: int = 0:
	set(new_base_block):
		base_block = new_base_block
		emit_changed()

# ── Behaviour ──────────────────────────────────────────────────────────────────

@export_group("Behaviour")

@export var ai_pattern: AiPattern = AiPattern.SEQUENTIAL:
	set(new_ai_pattern):
		ai_pattern = new_ai_pattern
		emit_changed()

## The default action pool used at full health (or when no phase is active).
@export var actions: Array[EnemyAction] = []:
	set(new_actions):
		actions = new_actions
		emit_changed()

# ── Phases ─────────────────────────────────────────────────────────────────────
## Optional. When the enemy's HP drops to or below a phase's hp_threshold,
## that phase's action pool replaces the active pool.
## Sort phases by hp_threshold descending (e.g. 0.75 → 0.5 → 0.25) so the
## combat system can find the correct phase with a simple linear scan.
## Leave empty for enemies with no phase changes (most Minions and Commanders).

@export_group("Phases")

@export var phases: Array[EnemyPhase] = []:
	set(new_phases):
		phases = new_phases
		emit_changed()
