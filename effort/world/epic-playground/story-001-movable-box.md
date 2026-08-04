---
xid: STO-WORLD-001
parent: ./epic.md
kind: story
effort: world
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-kj0
tasks: 3
complete: 3
---

# A box the player can push around

## Summary

A **box the player can move around** — a physics crate that slides when
the player walks into it (and that the mechanical arms can grab). Built
procedurally by the Playground.

## Definition of Done

- [x] A movable box exists in the level (a `RigidBody3D` crate with
      collision + mesh).
- [x] Walking the player into the box pushes it across the floor.
- [x] The box has low friction so it actually slides (isn't stuck).

## Verification notes (2026-08-03)

- Built in `scripts/playground.gd` (`_build_box`): a `RigidBody3D`
  "MovableBox" with a `BoxShape3D` collider, a `BoxMesh`, mass 2, and a
  low-friction `PhysicsMaterial` (0.15).
- Player push implemented in `scripts/player.gd` `_push_rigid_bodies()`
  — after `move_and_slide`, any `RigidBody3D` we slid against gets a
  central impulse in our travel direction (with a minimum push so a
  blocked player still shoves it).
- Headless test `tests/smoke_playground.gd`: **RESULT: PASS** — the box
  is a RigidBody3D and the player pushed it **1.34 m**.

## Out of scope

- Multiplayer sync of the box position (each peer builds its own for
  now) — capture as a follow-up if we want shared boxes.
- Picking the box up / carrying it with the arms (the arms currently
  pull the *player* toward a grab point, not the object).
