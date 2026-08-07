---
xid: STO-WORLD-005
parent: ./epic.md
kind: story
effort: world
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-218
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Pushing something into a wall pushes you back (Newton's third law)

## Summary

Newton's third law for shoving things. When the player pushes a
RigidBody that has nowhere to go — a crate jammed against a wall —
the push comes back into the player instead of vanishing. Each slide
contact probes whether the body can actually move
(`PhysicsServer3D.body_test_motion`, 5 cm); if it can't, the player's
intended push is reflected back as a rebound scaled by the object's
mass relative to a nominal player, and a short `_push_lock` holds the
rebound so walk input can't immediately overwrite it (the same trick
the wall-jump launch uses).

Mass scaling means a light crate against a wall just stops you with a
nudge, while something heavy genuinely shoves you back.

## Definition of Done

- [x] Pushing a FREE object still slides it and the player advances.
- [x] Pushing a JAMMED object barely moves it, stops the player short,
      and gives the player outward velocity.
- [x] The rebound survives held walk input (push lock).
- [x] Rebound magnitude scales with the object's mass.
- [x] `tests/smoke_push_reaction.gd` passes headless (6 checks,
      non-hosted).

## Out of scope

- Reaction from pushing enemies (they're CharacterBody3D, not
  RigidBody — a separate mechanic).
- Reaction when a ragdoll is jammed (parts are on their own layer and
  the player doesn't collide with them).

## Verification notes (2026-08-07)

- 6/6 PASS. Free vs jammed comparison (same walk, same box): box
  slides 1.97 m free vs 0.55 m jammed; player advances 3.60 m free vs
  1.81 m jammed; rebound peak 0.75 m/s jammed vs 0.00 m/s free. The
  comparison is the point — an absolute "player stops" assert would
  pass on plain collision alone.
- Two implementation bugs found via a throwaway probe:
  1. `move_and_slide()` rewrites `velocity` with the RESOLVED motion,
     so a blocked push read as ~0 and there was nothing to reflect.
     Fixed by capturing `_pre_move_velocity` before the move.
  2. The rebound was overwritten by walk input on the very next tick
     until `_push_lock` was added.
- Tuning: the first working version rebounded at 1.15x the push
  (5.75 m/s — faster than walking, off a 2 kg crate). Now a fraction
  of the push scaled by mass: 0.75 m/s for the light crate.
