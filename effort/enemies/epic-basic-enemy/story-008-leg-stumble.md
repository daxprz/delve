---
xid: STO-ENEMIES-008
parent: ./epic.md
kind: story
effort: enemies
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-rs3
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Stumble is a real leg buckle (partial leg ragdoll)

## Summary

The stumble tier (STO-ENEMIES-007) read as a whole-body lean, which
didn't look like stumbling. Now one LEG gives way: `Body.buckle_leg()`
takes a leg out of the procedural gait for the duration — its foot
stops stepping and collapses toward and behind the hip, so the knee
folds and the leg drags while the other leg carries the weight. The
side is chosen from the push direction (shoved right → the right leg
buckles), the fold depth scales with hit strength, and the torso now
only dips slightly (0.45 → 0.22 rad) instead of leaning bodily. The
leg recovers just before steering returns.

## Definition of Done

- [x] A medium hit buckles one leg (not just a body lean).
- [x] The buckling leg visibly folds: hip-to-foot distance shrinks.
- [x] The side follows the push direction; depth scales with strength.
- [x] The leg recovers before the stumble ends; gait resumes normally.
- [x] `tests/smoke_enemy_reactions.gd` passes headless (21 checks).

## Out of scope

- Buckling both legs (that's the ragdoll tier's job).
- An arm-flail counterbalance during the stumble.

## Verification notes (2026-08-07)

- 21/21 PASS. Measured fold: the buckling leg's hip-to-foot distance
  drops 0.90 m -> 0.68 m within 12 ticks of the hit.
- Timing gotcha: the buckle timer ticks in `Body._process` while the
  enemy's stumble timer ticks in `_physics_process` — equal durations
  raced. Buckle is now 0.8x the stumble so the leg is always back
  first.
