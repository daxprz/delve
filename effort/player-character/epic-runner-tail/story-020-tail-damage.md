---
xid: STO-CHARACTER-020
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-r23
tasks: 3
complete: 3
---

# The Runner's tail deals damage based on how fast it swings

## Summary

The Runner's fully-ragdoll tail is now a **weapon**: a tail segment that
**touches an enemy while moving fast** deals damage **scaled by its
speed**. So whip the tail around (sprint, turn hard, jump) to smack
enemies — a slow, dangling tail does nothing, a fast-swinging one hits
hard. Gives the armless Runner a way to fight back.

## Definition of Done

- [x] A fast-moving tail segment that hits an enemy deals damage.
- [x] Damage scales with the tail segment's speed (slow = no damage).
- [x] One swing = about one hit per enemy (per-enemy cooldown).

## Verification notes (2026-08-03)

- `tail.gd` `_hit_enemies`: for the outer segments, computes each point's
  speed from `(point - prev)/delta`; if above `TAIL_MIN_SPEED` (5) and
  within `TAIL_HIT_RADIUS` of an enemy in the `enemies` group, calls
  `take_damage(speed * TAIL_DAMAGE_SCALE)` (capped), with a per-enemy
  `TAIL_HIT_COOLDOWN`. Runs before the world-collision resolve (which
  would otherwise zero the segment velocities). Authority-only.
- `tests/smoke_tail_damage.gd`: **RESULT: PASS** — a settled/slow tail
  resting on an enemy does no damage; whipping the player side-to-side
  dropped the enemy 38 → 18.

## Out of scope

- Knocking enemies back with the tail; the tail only damages enemies
  (not the box / rigid bodies). Multiplayer damage authority.
