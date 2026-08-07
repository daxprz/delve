---
xid: STO-CHARACTER-034
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-5s9
shipped: 2026-08-07
tasks: 4
complete: 4
---

# Tail drapes over the player's legs instead of phasing through

## Summary

The Runner's tail no longer phases through its own body. Ray-based
world collision couldn't fix this: the legs are procedural VISUALS
with no physics shapes, so there was nothing to hit. Instead the tail
solver now pushes its points out of analytic capsules every iteration
— a torso capsule through the player's middle, plus thigh and shin
bones read live from `Body.leg_capsules()` (which follow the walk
gait). Contact damps the into-surface velocity but keeps the sliding
component (`BODY_FRICTION`), so the tail slides over and drapes/wraps
around a leg rather than bouncing off it.

## Definition of Done

- [x] `Body.leg_capsules()` exposes live thigh/shin bones (+
      `knee_world`).
- [x] No tail point ends up inside the torso or a leg capsule, at
      rest or while walking.
- [x] The tail still hangs naturally (not shoved away) and the Verlet
      chain stays stable.
- [x] `tests/smoke_tail_body.gd` passes headless (7 checks,
      non-hosted).

## Out of scope

- Tail collision against OTHER players' bodies (only the owner's).
- Arms/head capsules — the torso capsule covers them well enough.
- Real per-leg physics shapes (heavier, and the gait already moves
  the capsules).

## Verification notes (2026-08-07)

- 7/7 PASS. Clearances: torso 0.110 m / leg 0.366 m at rest, 0.779 m
  / 0.676 m while walking — no penetration in any sampled tick.
- Push-out runs INSIDE the constraint iterations so the length
  constraints and the body contact converge together.
