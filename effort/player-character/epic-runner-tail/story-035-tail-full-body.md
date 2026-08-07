---
xid: STO-CHARACTER-035
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-s6q
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Tail collides with every body part (torso, head, arms)

## Summary

Extends STO-CHARACTER-034 from "torso + legs" to **every solid body
part**. `Body.body_capsules()` now returns the full world-space
capsule set — torso (pelvis→neck), neck+head (through the skull top),
both arms (shoulder→elbow, elbow→hand) and both legs — with radii
derived from the built segment sizes, so they track this individual's
procedural proportions and move with the walk gait and arm swing. The
tail solver pushes its points out of all of them, so the tail can no
longer pass through the body, the arms or the head.

## Definition of Done

- [x] `body_capsules()` covers torso, neck/head, arms and legs (10
      capsules for a human-armed build).
- [x] No tail point inside ANY capsule at rest or while walking
      (arms/legs swinging).
- [x] Points forcibly jammed into body-part centres are ejected.
- [x] Tail still hangs naturally; chain stays stable.
- [x] `tests/smoke_tail_body.gd` passes headless (8 checks).

## Out of scope

- Hands/feet as separate capsules (the forearm/shin capsules reach
  far enough).
- Collision with other players' bodies.

## Verification notes (2026-08-07)

- 8/8 PASS. The at-rest/walking checks pass with large margins (the
  tail rarely reaches the head or arms in normal play), so the test
  adds a STRESS phase: 10 tail points are teleported to the exact
  centre of each body capsule and must be ejected. All 10 were pushed
  clear within 3 ticks — worst clearance +0.116 m — which is what
  actually proves the constraint fires, rather than the tail merely
  never being nearby.
