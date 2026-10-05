# Handoff: Brute boss enemy — Godot 4.x 3D scene

## Overview
Build a single reusable enemy — a heavy melee "brute" boss — as a Godot 4.x **3D** scene driven by a
2D sprite sheet (billboarded `AnimatedSprite3D` in a 3D world, sometimes called 2.5D or "Doom-style"
sprite enemy). The scene must ship with: 7 animations wired to a `SpriteFrames` resource, a physics
body with collision, damage-dealing hitboxes that activate only on specific frames, a hurtbox that
receives damage, and a state machine that sequences idle → walk → attack → hurt → death.

The sprite art itself does **not** exist yet. This handoff defines the frame plan, the atlas geometry,
the timing, and the node structure so the scene can be built and tested against a placeholder atlas,
then swapped to final art with no code changes.

## About the design files
`Brute Boss Sprite Sheet Wireframe.dc.html` in this bundle is a **design reference created in HTML** —
a frame-planning wireframe, not production code and not art. Do not port its markup, CSS, or layout
into Godot. Read it as the spec document for the sprite sheet: which animations exist, how many frames
each has, which frames are pose extremes, which frames deal damage, where the pivot and ground line
sit inside each cell.

Nothing in the HTML file becomes a runtime asset. The deliverable is a Godot scene + scripts +
resources.

## Fidelity
**Low-fidelity.** The HTML is a wireframe: empty labeled frame cells and box-blockout proportions.
There is no final art, no final palette, no rendered character. Treat the frame counts, frame labels,
fps values, pivot, baseline, and hit-frame markers as **authoritative**. Treat everything visual
(colors, shading, silhouette detail) as **not yet specified** — use a placeholder atlas until the
artist delivers.

## Target environment
- **Godot 4.3+** (any 4.x; use `4.3` project features unless the existing project pins otherwise).
- **Renderer:** Forward+ or Mobile. Both work; Compatibility also fine.
- **Language:** GDScript. If the target project is C#, mirror the same node structure and API calls.
- If an existing project is provided, follow its folder conventions, autoload names, damage interface,
  and group names instead of the ones invented below — the names here are defaults, not requirements.

---

## The sprite atlas

| Property | Value |
|---|---|
| Cell size | 192 × 192 px |
| Grid | 10 columns × 7 rows |
| Atlas size | 1920 × 1344 px |
| Format | PNG-32, straight (non-premultiplied) alpha |
| Filtering | **Nearest**, no mipmaps, no trimming, no padding between cells |
| Pivot inside cell | x = 96, y = 176 (bottom-center, on the ground line) |
| Ground line (baseline) | y = 176 within the cell — feet contact here on all grounded frames |
| Headroom | Top 8 px of the cell is reserved so the roar and slam apex do not clip |
| Character height | ~92% of cell height |
| Palette | 12 colors — 8 body, 2 weapon, 2 rim |

Rows are laid out top to bottom in this order. Unused columns in a row are fully transparent and must
not be added as frames.

| Row (0-idx) | Animation | Frames | FPS | Loop | Notes |
|---|---|---|---|---|---|
| 0 | `idle` | 6 | 12 | yes | Slow breathe, weapon dragging on the ground |
| 1 | `walk` | 8 | 14 | yes | Heavy cycle, 2-frame contact hold |
| 2 | `slam` | 10 | 16 | no | Long telegraph, 1 active frame, slow recovery |
| 3 | `sweep` | 8 | 16 | no | Faster commit, 2 active frames, punishable tail |
| 4 | `hurt` | 3 | 18 | no | White flash on frame 1 |
| 5 | `roar` | 6 | 12 | no | Buff / aggro switch, camera shake |
| 6 | `death` | 10 | 10 | no | Holds on the final frame forever |

Total 51 frames: 16 pose extremes ("KEY" in the wireframe) and 35 in-betweens.

### Per-frame detail

Frame numbers are 1-based as labeled in the wireframe; `SpriteFrames` indices are 0-based (subtract 1).
`KEY` = pose extreme, informational only. `HIT` = the hitbox must be enabled for the duration of that
frame and disabled again after.

**idle** (row 0) — `1 settle KEY`, `2 rise`, `3 peak KEY`, `4 hold`, `5 fall`, `6 low`

**walk** (row 1) — `1 contact L KEY`, `2 down`, `3 pass KEY`, `4 up`, `5 contact R KEY`, `6 down`,
`7 pass KEY`, `8 up`

**slam** (row 2) — `1 crouch KEY`, `2 lift`, `3 raise`, `4 apex hold KEY`, `5 drop`,
`6 impact KEY HIT`, `7 dust HIT`, `8 settle`, `9 drag up`, `10 recover KEY`

**sweep** (row 3) — `1 wind back KEY`, `2 coil`, `3 release`, `4 sweep A KEY HIT`, `5 sweep B HIT`,
`6 follow`, `7 off balance KEY`, `8 recover`

**hurt** (row 4) — `1 snap back KEY`, `2 hold`, `3 return`

**roar** (row 5) — `1 inhale KEY`, `2 chest up`, `3 open KEY`, `4 full roar KEY`, `5 sustain`, `6 close`

**death** (row 6) — `1 stagger KEY`, `2 knee`, `3 drop weapon KEY`, `4 fall fwd`, `5 impact KEY`,
`6 bounce`, `7 still KEY`, `8 dissolve 1`, `9 dissolve 2`, `10 gone KEY`

### Derived timings (for tuning windows, at the fps above)

- `slam` total 10 / 16 fps = **625 ms**; telegraph = frames 1–5 = 312 ms; active = frames 6–7 = 125 ms;
  recovery = frames 8–10 = 188 ms.
- `sweep` total 8 / 16 = **500 ms**; telegraph = frames 1–3 = 188 ms; active = frames 4–5 = 125 ms;
  recovery = frames 6–8 = 188 ms.
- `hurt` total 3 / 18 = **167 ms**.
- `roar` total 6 / 12 = **500 ms**; camera shake spans frames 3–5 (167–417 ms).
- `death` total 10 / 10 = **1000 ms**, then hold.

### Proportion blockout (for the artist and for collider sizing)

All values in sprite pixels inside the 192 × 192 cell, origin top-left:

| Part | Box | Notes |
|---|---|---|
| Overall volume | 108 × 90 at (42, 48) | Loose bounding envelope |
| Torso | 74 × 58 at (59, 76) | Center of mass |
| Head | 32 × 26 at (80, 48) | Deliberately small relative to shoulders |
| Arms (L / R) | 20 × 80 at (38, 78) and (134, 78) | Long, hanging below the hips |
| Legs (L / R) | 26 × 42 at (66, 134) and (100, 134) | |
| Weapon | 14 × 108 at (150, 64) | Readability anchor — must differ in value from the body every frame |

Silhouette rules from the wireframe, carried over as art direction: heavy shoulders, small head, long
arms; hips forward of the ankles so the mass reads as dragged, not carried; asymmetry (one arm heavier,
one shoulder higher).

---

## Scene structure

Create `res://enemies/brute_boss/brute_boss.tscn`:

```
BruteBoss                 CharacterBody3D          script: brute_boss.gd
├── Sprite                AnimatedSprite3D         the visual
├── Body                  CollisionShape3D         CapsuleShape3D, world collision
├── Hurtbox               Area3D                   receives player damage
│   └── CollisionShape3D  CapsuleShape3D
├── SlamHitbox            Area3D                   monitoring = false by default
│   └── CollisionShape3D  BoxShape3D
├── SweepHitbox           Area3D                   monitoring = false by default
│   └── CollisionShape3D  BoxShape3D
├── AggroRange            Area3D                   idle → chase trigger
│   └── CollisionShape3D  SphereShape3D  radius 14
├── AttackRange           Area3D                   chase → attack trigger
│   └── CollisionShape3D  SphereShape3D  radius 2.6
└── Audio                 AudioStreamPlayer3D
```

### World scale

Pick **1 sprite pixel = 0.02 m**, so the 176 px tall character is **3.52 m** — a boss roughly twice
player height. This makes the whole 192 px cell 3.84 m.

`AnimatedSprite3D` settings:

| Property | Value |
|---|---|
| `pixel_size` | `0.02` |
| `billboard` | `BaseMaterial3D.BILLBOARD_FIXED_Y` (stays upright, yaws to camera) |
| `centered` | `true` |
| `offset` | `Vector2(0, 16)` — see below |
| `transparent` | `true` |
| `alpha_cut` | `ALPHA_CUT_DISCARD` (crisp edges + correct depth sorting; use `ALPHA_CUT_HASH` only if soft edges are wanted later) |
| `texture_filter` | `BASE_TEXTURE_FILTER_NEAREST` |
| `shaded` | `false` unless the level needs the enemy lit; if `true`, also enable `double_sided = false` |
| `no_depth_test` | `false` |

**Offset math.** The atlas pivot is at cell y = 176, but a centered sprite pivots at y = 96. The
sprite must sit 80 px higher than center so the node origin lands on the character's feet:
`offset.y = (176 - 96) / 2` in the `AnimatedSprite3D`'s own units → set `offset = Vector2(0, 40)`
if `centered` is true and offset is applied in texture pixels pre-scale. **Verify empirically:** place
the scene on a flat floor and confirm the feet touch y = 0. If they float or sink, adjust `offset.y`
only — never move the `CharacterBody3D` origin, because the state machine, hitboxes, and navigation
all assume the node origin is the ground contact point.

Collider sizes (derived from the blockout × 0.02):

- `Body` capsule: radius `0.9`, height `3.4`, positioned at `y = 1.7`.
- `Hurtbox` capsule: radius `1.0`, height `3.5`, at `y = 1.75` (slightly generous so the player's hits
  land).
- `SlamHitbox` box: `size = Vector3(2.8, 1.0, 2.8)`, at `y = 0.5`, `z = -1.8` in front of the body — a
  ground-impact area, not a weapon arc.
- `SweepHitbox` box: `size = Vector3(4.4, 1.6, 2.0)`, at `y = 1.4`, `z = -1.4` — wide horizontal arc.

Physics layers (rename to match the project if it already has a layer scheme):

| Layer | Name | Used by |
|---|---|---|
| 1 | world | `Body` collision |
| 2 | player | — |
| 3 | player_hitbox | what `Hurtbox` monitors |
| 4 | enemy_hurtbox | `Hurtbox` layer |
| 5 | enemy_hitbox | `SlamHitbox`, `SweepHitbox` layer; player hurtbox monitors it |

---

## Resources to generate

### `res://enemies/brute_boss/brute_boss_frames.tres` (`SpriteFrames`)

Seven animations named exactly `idle`, `walk`, `slam`, `sweep`, `hurt`, `roar`, `death`, with the
fps and loop flags from the row table. Frames come from the atlas by grid position — either via the
editor's "Add frames from sprite sheet" dialog (horizontal 10, vertical 7, select the cells for that
row) or generated in code. A generator script is preferable so re-exported art needs no manual
re-slicing:

```gdscript
# res://tools/build_brute_frames.gd  — run once via editor script or @tool button
@tool
extends EditorScript

const CELL := 192
const ROWS := [
	{"name": "idle",  "row": 0, "count": 6,  "fps": 12.0, "loop": true},
	{"name": "walk",  "row": 1, "count": 8,  "fps": 14.0, "loop": true},
	{"name": "slam",  "row": 2, "count": 10, "fps": 16.0, "loop": false},
	{"name": "sweep", "row": 3, "count": 8,  "fps": 16.0, "loop": false},
	{"name": "hurt",  "row": 4, "count": 3,  "fps": 18.0, "loop": false},
	{"name": "roar",  "row": 5, "count": 6,  "fps": 12.0, "loop": false},
	{"name": "death", "row": 6, "count": 10, "fps": 10.0, "loop": false},
]

func _run() -> void:
	var sheet: Texture2D = load("res://enemies/brute_boss/brute_boss_sheet.png")
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for def in ROWS:
		frames.add_animation(def.name)
		frames.set_animation_speed(def.name, def.fps)
		frames.set_animation_loop(def.name, def.loop)
		for col in def.count:
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(col * CELL, def.row * CELL, CELL, CELL)
			at.filter_clip = true
			frames.add_frame(def.name, at)
	ResourceSaver.save(frames, "res://enemies/brute_boss/brute_boss_frames.tres")
```

### Placeholder atlas

Until real art arrives, generate a 1920 × 1344 placeholder PNG: each used cell gets a 1 px outline,
its `NN label` text, a dashed line at y = 176, a cross at (96, 176), and a solid block roughly matching
the torso box so motion is visible when the animation plays. Unused cells stay transparent. This lets
every state, hitbox window, and transition be tested before the artist delivers.

### Damage data

`res://enemies/brute_boss/brute_boss_stats.tres` — a small `Resource` so tuning does not require code
edits:

| Field | Value |
|---|---|
| `max_health` | `600` |
| `move_speed` | `2.4` m/s |
| `turn_speed` | `3.0` rad/s |
| `slam_damage` | `45` |
| `sweep_damage` | `30` |
| `slam_knockback` | `9.0` |
| `sweep_knockback` | `5.0` |
| `hurt_threshold` | `40` — damage in one hit needed to interrupt into `hurt` |
| `attack_cooldown` | `1.2` s |
| `aggro_radius` | `14.0` |
| `attack_radius` | `2.6` |

---

## State machine

Seven states, one per animation. Implement as an enum + `match` in `_physics_process`, or as child
nodes if the project already has a state-machine pattern — follow the project's existing convention.

| State | Enter | Behavior | Exit |
|---|---|---|---|
| `IDLE` | play `idle` | no movement, faces player slowly | player enters `AggroRange` → `ROAR` (first time only) or `CHASE` |
| `CHASE` | play `walk` | move toward player at `move_speed`, gravity applied | in `AttackRange` and off cooldown → `SLAM` or `SWEEP`; player leaves `aggro_radius * 1.4` → `IDLE` |
| `SLAM` | play `slam`, movement locked | hitbox on for frames 6–7 | `animation_finished` → `CHASE`, start cooldown |
| `SWEEP` | play `sweep`, movement locked | hitbox on for frames 4–5, small forward lunge (0.6 m over frames 3–5) | `animation_finished` → `CHASE`, start cooldown |
| `HURT` | play `hurt`, cancel active hitboxes, white flash | movement locked | `animation_finished` → `CHASE` |
| `ROAR` | play `roar`, emit `roared` for camera shake on frame 3 | movement locked | `animation_finished` → `CHASE` |
| `DEATH` | play `death`, disable `Hurtbox` + `Body` collision, emit `died` | movement locked, gravity still applied | never — hold final frame |

Attack selection when in range and off cooldown: `SWEEP` if the player is within 2.0 m (close, wide
arc), otherwise `SLAM`. 65/35 random weighting toward `SLAM` when both are valid, so the boss is not
fully predictable.

`HURT` interrupts `CHASE` and `IDLE` freely. It interrupts `SLAM` / `SWEEP` **only before** the active
frames — once the hitbox is live the attack completes (standard boss commitment). `DEATH` interrupts
everything.

### Frame-accurate hitboxes

Do not use timers. Drive hitbox activation off the sprite's current frame so it stays correct if fps
is retuned:

```gdscript
const HIT_WINDOWS := {
	"slam":  {"from": 5, "to": 6, "box": "SlamHitbox",  "damage_key": "slam_damage"},
	"sweep": {"from": 3, "to": 4, "box": "SweepHitbox", "damage_key": "sweep_damage"},
}  # 0-based, inclusive

func _on_sprite_frame_changed() -> void:
	var anim := sprite.animation
	if not HIT_WINDOWS.has(anim):
		return
	var w: Dictionary = HIT_WINDOWS[anim]
	var box: Area3D = get_node(w.box)
	var active := sprite.frame >= w.from and sprite.frame <= w.to
	box.monitoring = active
	if active and not _hit_this_swing.has(anim):
		pass  # bodies entering are damaged in the box's own body_entered handler
```

Connect `AnimatedSprite3D.frame_changed` to that handler, and `animation_finished` to the state exit
logic. Each attack must damage a given target **at most once per swing** — clear a `_hit_bodies` set
on state enter and check it in the hitbox's `body_entered`.

### Signals to expose

`signal roared`, `signal died`, `signal health_changed(current: int, max: int)`,
`signal attack_started(kind: StringName)`. These let the arena, HUD, and camera react without reaching
into the enemy.

---

## Visual effects (frame-anchored)

| Effect | Trigger | Detail |
|---|---|---|
| Hit flash | `HURT` enter | Tint the sprite white for 1 frame (~56 ms) via `modulate` or a shader `flash` uniform, then lerp back over 120 ms |
| Ground dust | `slam` frame 7 (`dust`) | `GPUParticles3D` one-shot at the impact point, radial |
| Camera shake | `slam` frame 6, `roar` frames 3–5 | Slam: 0.35 amplitude, 200 ms decay. Roar: 0.15 sustained |
| Dissolve | `death` frames 8–10 | Shader `dissolve` uniform 0 → 1, driven off `frame`; keep the final frame visible at full dissolve or free the node 1.5 s after `died` |
| Weapon drop | `death` frame 3 | Optional separate prop scene spawned and left in the world |
| Telegraph tell | `slam` frame 4 (`apex hold`), `sweep` frame 1 (`wind back`) | Brief audio cue so the player can read the attack without watching the sprite |

Motion feel, matching the design system's motion rules: state changes ease with
`cubic-bezier(.4, 0, .2, 1)` equivalents (`Tween.TRANS_CUBIC`, `EASE_IN_OUT`) over ~200 ms; no bounce
easings anywhere.

---

## Test scene

`res://enemies/brute_boss/brute_boss_test.tscn` — a flat `StaticBody3D` floor, a `Camera3D` at
`(0, 4, 10)` looking at `(0, 1.75, 0)`, a `DirectionalLight3D`, one `BruteBoss` instance, and an
on-screen `Control` with:

- One button per animation, forcing that state.
- A "damage 20" and a "damage 60" button, to prove the `hurt_threshold` interrupt.
- A frame-number and state-name readout.
- A "show hitboxes" toggle (`get_tree().debug_collisions_hint` is editor-only; instead toggle
  `MeshInstance3D` wireframe children on the Area3Ds).
- An fps slider per animation so the artist and designer can retune timing live before values are
  baked into the `SpriteFrames`.

## Acceptance checklist

- [ ] Feet sit exactly on the floor plane in every grounded frame; no float, no sink, no shimmer while
      the camera orbits.
- [ ] Sprite stays upright and faces the camera from all yaw angles; never tilts when the camera pitches.
- [ ] Pixels are crisp at close range — no bilinear smearing, no atlas bleed from neighboring cells.
- [ ] All 7 animations play at the specified fps; `idle` and `walk` loop, the other five do not.
- [ ] `death` holds its final frame indefinitely and never restarts.
- [ ] `slam` damages only during frames 6–7 and `sweep` only during frames 4–5, verified with the
      hitbox debug view.
- [ ] A single swing cannot damage the same target twice.
- [ ] A 60-damage hit interrupts `chase` into `hurt`; a 20-damage hit does not.
- [ ] An attack already past its telegraph cannot be interrupted by `hurt`.
- [ ] Retuning an animation's fps changes its speed without breaking hitbox windows.
- [ ] Swapping the placeholder atlas for the final PNG requires no script changes.

## Assets
- **Sprite atlas:** not yet produced. Expected at
  `res://enemies/brute_boss/brute_boss_sheet.png`, 1920 × 1344, PNG-32. Build against a generated
  placeholder until the artist delivers.
- **Audio:** not specified. Placeholders needed for slam impact, sweep whoosh, roar, hurt, death.
- **No third-party assets.** The creature is an original design — do not source or reference art from
  any existing commercial game.

## Files in this bundle
- `README.md` — this document.
- `Brute Boss Sprite Sheet Wireframe.dc.html` — the frame-plan wireframe. Open in a browser. Design
  reference only.
