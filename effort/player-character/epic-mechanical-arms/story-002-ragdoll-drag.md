---
xid: STO-CHARACTER-002
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: [STO-CHARACTER-001]
bd-id: delve-4cj
tasks: 5
complete: 5
---

# The arms ragdoll and drag behind the player

## Summary

The two arms become **floppy physics ragdolls**. Instead of sticking
out stiffly, the arm segments swing on joints, get pulled down by
gravity, and **trail and drag behind** the player as they walk, turn,
and jump — like heavy chains or noodle arms. When the player stops, the
arms settle and dangle.

This piece is only about the *floppy dragging* feel. Grabbing comes in
story 003.

## Definition of Done

- [x] Each arm's segments are connected by physics joints and swing
      freely (ragdoll).
- [x] Gravity pulls the arms down so they hang when standing still.
- [x] When the player moves, the arms trail and drag behind instead of
      staying rigid.
- [x] The arms don't fly out crazily or explode — they stay attached
      at the shoulder and calm down when the player stops.
- [x] A debug aspect can draw the joints/segments so we can see the
      ragdoll working.

## Verification notes (2026-08-03)

- Implemented as a **procedural Verlet solver** in
  `scripts/mechanical_arms.gd` (`_simulate_arm`): 4 points per arm
  (shoulder, elbow, wrist, fingertip), gravity + damping integration,
  segment-length relaxation, floor clamp. No RigidBody — fully code
  generated, which keeps it stable.
- The shoulder point is pinned to the player, so the arms follow the
  body and **drag/trail** as it moves; gravity makes them hang at rest.
- Headless test `tests/smoke_ragdoll.gd`: **RESULT: PASS** — points
  stay finite (no explosion), shoulder stays pinned (1.55 m), the hand
  hangs 1.20 m below the shoulder, and the hand trails behind while
  moving (dz = 1.81 m).
- Joints/segments are visible meshes (joint spheres + limb boxes), so
  the ragdoll is directly observable; a formal `DebugOverlay` aspect is
  deferred until that autoload lands (delve's target infra).

### Change 2026-08-03 — heavier + always solid

Operator wanted the arms to feel **heavier** (not instantly snap to grab
points) and to **always stay in one piece** (never split into 2 parts) —
solid, but still jointed.

- **Heavier:** more Verlet drag (`DAMPING` 0.98 → 0.96) so the arms move
  with more weight, and grabbing now **eases** the fingertip toward the
  target (`GRAB_REACH_LERP` 0.18) over several frames instead of hard-
  snapping it there.
- **Always solid:** removed the hard fingertip pin (which stretched the
  arm apart when the grab point was beyond reach). Now only the shoulder
  is pinned and segment lengths are enforced with more iterations
  (`SOLVER_ITERATIONS` 10 → 16), so the arm bends at its joints but never
  pulls apart. If a grab is out of reach the arm just extends toward it,
  staying whole.
- New test `tests/smoke_arm_solid.gd`: **RESULT: PASS** — grabbing a
  point 5 m out of reach, the arm's worst segment stretch stayed x1.01
  (solid), and the hand was still 4.24 m off after one frame (heavy, no
  snap).

## Out of scope

- Grabbing onto things (story 003).
- Fancy collision between the arms and the world (keep it simple; note
  it as a future idea if it looks bad).
