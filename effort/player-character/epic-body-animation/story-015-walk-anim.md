---
xid: STO-CHARACTER-015
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-nc2
tasks: 3
complete: 3
---

# The body animates procedurally (legs/arms swing when walking)

## Summary

The humanoid body **animates itself procedurally** — no premade
animation clips. A walk phase advances with the player's movement speed;
`sin(phase)` swings the thighs (with the knees bending) and the arms
swing opposite the legs, plus a small up/down bob. Standing still gives a
gentle idle sway.

## Definition of Done

- [x] Walking swings the legs (amplitude scales with speed).
- [x] Arms swing opposite the legs (on characters that have human arms).
- [x] Knees bend and the body bobs slightly; idle sway when still.

## Verification notes (2026-08-03)

- `scripts/body.gd` `_process`: derives speed from the player's
  per-frame position change, advances `_walk_phase`, and sets each
  thigh/shin/upper-arm joint's `rotation.x` from `sin(phase)` (left/right
  and arms/legs in opposite phase), plus a pelvis bob. All from code.
- `tests/smoke_body_anim.gd`: **RESULT: PASS** — while walking, the
  thigh swing reached 0.17 rad (animating).

### Change 2026-08-03 — real procedural gait (stepping feet + IK)

Upgraded from simple hip-swing to a **procedurally generated walk**: the
feet actually **step and plant on the ground** with bending knees.

- [x] Each foot stays planted in world space; when it lags too far behind
      the moving hip it **takes a step** — lerping to a spot ahead while
      **lifting in an arc** (`STEP_LIFT`). The feet alternate.
- [x] The legs bend to reach the foot via **2-bone inverse kinematics**
      (`_solve_leg` / `_aim_basis`) with the knee pointing forward.
- [x] Planted feet track the ground height (stand still = no sliding;
      works on the raised ground too).
- `tests/smoke_body_anim.gd` updated: **RESULT: PASS** — while walking a
  foot lifts 0.16 m off the ground (a real step), not sliding.

### Fixes 2026-08-03 — foot direction, stepping, idle planting

- [x] **Feet were facing the wrong way.** The foot inherited the shin's
      tilt, pointing the toe backward. Now each foot is oriented flat and
      toe-forward (`Basis.looking_at(-forward)`), lifted slightly
      (`FOOT_RAISE`) so it rests on the ground.
- [x] **Weird stepping.** Retuned the gait (shorter stride/quicker
      steps) for a smoother alternate.
- [x] **Feet floated when standing.** When idle, the target is now
      directly under the hip (not ahead), the planted foot is clamped to
      the ground each frame, and a foot may still take a small settling
      step — so when you stop the feet plant under you instead of drifting.
- `tests/smoke_body_anim.gd`: **RESULT: PASS** — a foot lifts 0.14 m
  while walking, and after stopping the feet rest 0.00 m off the ground.

### Fix 2026-08-03 — legs don't drag behind

- [x] Operator: walking dragged the legs behind. The Runner (8 m/s)
      moves faster than short legs can stride, so planted feet fell far
      behind. Fixed by (a) leading the step toward where the hip will be,
      and (b) hard-clamping every foot to within `MAX_STEP` (0.5 m) of
      its hip, so a leg can never stretch far ahead or behind (at worst
      the foot slides a little). `tests/smoke_body_anim.gd`: **RESULT:
      PASS** — max foot-to-hip distance while walking is 0.50 m (was
      2.4 m).

## Out of scope

- Foot raycast to conform to slopes/edges, and blending between states.
