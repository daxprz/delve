---
xid: STO-CHARACTER-011
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-eh5
tasks: 3
complete: 3
---

# The arms and tail clip against everything, not just the floor

## Summary

The arms (Grabber) and tail (Runner) are Verlet chains that previously
only stopped at the floor. Now every link **collides with all solid
geometry** — walls, pillars, the movable box, enemies — so the chains
rest against and drape over surfaces instead of passing through them.

## Definition of Done

- [x] Each arm segment is kept out of solid geometry (not just floor).
- [x] Each tail segment is kept out of solid geometry (not just floor).
- [x] The chains stay stable (no jitter-explosions) with collision on.

## Verification notes (2026-08-03)

- After the length solver, each chain link is ray-checked from its joint
  to its far point (`_collide_chain` in `mechanical_arms.gd`; the same
  loop in `tail.gd`). On a hit, the far point is placed just off the
  surface (`CHAIN_MARGIN`) and its velocity into the surface is killed,
  so it rests against the geometry. The player's own body is excluded.
- `tests/smoke_chain_collision.gd`: **RESULT: PASS** — with a solid
  shelf under the Grabber, the arms rest on it (lowest hand y=1.46)
  instead of falling through to the floor.
- All arm/tail/grab/ragdoll tests still pass (collision didn't
  destabilise the chains).

## Out of scope

- The chains pushing dynamic bodies (they rest against them, they don't
  shove them). Self-collision between links.
