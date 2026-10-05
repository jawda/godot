class_name BruteBossStats
extends Resource

## Tuning values for the brute boss. Kept as a resource so combat can be
## rebalanced by editing brute_boss_stats.tres — no script changes needed.
## Values mirror the "Damage data" table in the handoff README.

@export var max_health: int = 600
@export var move_speed: float = 2.4          # metres / second
@export var turn_speed: float = 3.0          # radians / second
@export var slam_damage: int = 45
@export var sweep_damage: int = 30
@export var slam_knockback: float = 9.0
@export var sweep_knockback: float = 5.0
@export var hurt_threshold: int = 40         # single-hit damage needed to interrupt into hurt
@export var attack_cooldown: float = 1.2     # seconds
@export var aggro_radius: float = 14.0
@export var attack_radius: float = 2.6
