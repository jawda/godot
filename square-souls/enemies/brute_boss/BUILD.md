# Brute boss — grey-box build

First pass of the enemy, built as a **3D primitive rig** (capsules, sphere, box)
on a `Node3D` joint hierarchy, animated with an `AnimationPlayer`. The colliders,
hitboxes, ranges and stats from the handoff (`../../README.md`) carry over; the
combat state machine is a later pass.

> Note: this deviates from the handoff, which specified a 2.5D billboarded sprite
> enemy. We pivoted to a true-3D grey-box so the motion reads with real depth.

## Files

| File | What it is |
|---|---|
| `brute_boss.tscn` / `brute_boss.gd` | The reusable enemy. `CharacterBody3D` + a `Figure` joint rig (pelvis → spine → arm/head, plus legs) built from primitive meshes, an `Animator` (`AnimationPlayer`) holding all 7 clips (idle, walk, slam, sweep, hurt, roar, death), world collision, hurtbox, slam/sweep hitboxes (disabled), aggro/attack ranges. |
| `brute_boss_stats.gd` / `.tres` | Tuning values (health, speeds, damage…). |
| `brute_boss_view.tscn` / `.gd` | Minimal preview: floor, light, orbiting camera. |

## Setup

1. Open the project in Godot 4.7.
2. Open `brute_boss_view.tscn` and press **Play Scene** (`F6` / `F5`).

That's it — no build step. The animation clips are stored inside the scene's
`AnimationPlayer` and the `idle` clip autoplays.

## Preview controls

- **1–7** — play idle / walk / slam / sweep / hurt / roar / death.
- **← / →** — orbit the camera.

## The rig

```
BruteBoss (CharacterBody3D)
└─ Figure (Node3D)
   ├─ LeftLeg / RightLeg (Node3D, hip)   ← walk swings these (rotation.x)
   │  ├─ Thigh (capsule)
   │  └─ Left/RightKnee (Node3D, knee)   ← bend available for future poses
   │     └─ Calf (capsule)
   └─ Pelvis (Node3D)            ← crouch / slam-drop (animates position.y)
      └─ Spine (Node3D)          ← lean forward / back (rotation.x), twist (rotation.y)
         ├─ Chest (capsule)      ← wide shoulders
         ├─ Belly (sphere)       ← bulges forward (−Z)
         ├─ Head (Node3D) → Form (sphere)
         └─ ArmRig (Node3D)      ← the weapon swing pivot (rotation.x)
            ├─ Left/RightArm (Node3D, shoulder)
            │  ├─ UpperArm (capsule)
            │  └─ Left/RightElbow (Node3D, elbow) → Forearm (capsule)
            └─ Weapon (box)      ← child of ArmRig, so it swings in true 3D
```

Rotating a pivot moves everything under it, so the whole slam is a few joint
rotations over time. Knees and elbows are their own pivots now, so limbs can bend
independently (nothing animates them yet — they're straight at rest). The brute
faces **−Z** (front); the slam/sweep hitboxes and the belly sit in front of it.

## Tuning animations

Select the `Animator` node in `brute_boss.tscn` and open the **Animation** panel
(bottom of the editor). Pick a clip, scrub the timeline, drag keys, add/remove
keyframes — it all saves with the scene. No script, no build step. (Claude can
also edit the keyframe values directly in the `.tscn` text when you ask.)

Axes cheat-sheet:
- `ArmRig.rotation.x`: swings the weapon in the *sagittal plane* (front/back) —
  from the front camera this reads as "up the middle". 0 = down, 90° = forward,
  180° = straight overhead. The slam rises 20°→178° up the middle to overhead,
  then the strike comes back down.
- `ArmRig.rotation.z`: swings it in the *frontal plane* (side to side). The
  strike ramps in a little z (~30°) near the end so the weapon arcs off to one
  side, finishing pointing down-and-to-the-side.
- `Spine.rotation.x`: + leans back, − leans forward. `Spine.rotation.y`: twist.

## Deferred to the next pass

Seven-state machine, frame-accurate hitbox windows, damage/interrupt logic,
signals, visual-effect hooks, and the full test HUD.
