---
xid: STO-ENEMIES-004
parent: ./epic.md
kind: story
effort: enemies
size: M
status: shipped
date: 2026-08-06
depends-on: []
bd-id: delve-ndq
shipped: 2026-08-06
tasks: 5
complete: 5
---

# Physical hit reactions: trips, knockdowns, tumbling

## Summary

Enemies react physically to hits (STO-ENEMIES-004). A knockdown/tumble
state in `enemy.gd`: strong knockbacks (punch, shockwave, throw,
parry — anything ≥ `RAGDOLL_IMPULSE` through `apply_knockback`) bowl
the enemy over; it tumbles around a push-perpendicular axis while
flying, slides with low friction (gets pushed around), settles flat
on the ground, then stands back up after ~1.6 s. A new `trip()` entry
point gives the Runner's tail a foot-sweep: swipes faster than
`TAIL_TRIP_SPEED` (9 m/s) trip the enemy in the swipe direction. Gait
IK is suspended while down and restored on getting up.

## Definition of Done

- [x] Weak knockback still only staggers (no knockdown).
- [x] Knockback ≥ threshold knocks the enemy down; the body visibly
      tumbles/tips and the enemy slides along the ground.
- [x] The enemy settles lying flat, then gets back up with the body
      upright and gait animation re-enabled.
- [x] Fast tail swipes call `trip()`; `trip()` knocks down.
- [x] `tests/smoke_enemy_reactions.gd` passes headless (7 checks, no
      networking).

## Out of scope

- Per-limb physical ragdoll (jointed RigidBody chain) — the tumble is
  a whole-body fake ragdoll, consistent with the game's procedural
  style.
- Enemies damaging players (they still only chase).

## Verification notes (2026-08-06)

- `smoke_enemy_reactions`: 7/7 PASS — stagger vs knockdown threshold,
  tumble (max tip 3.13 rad), slide 7.3 m after |impulse|=10 hit
  (DOWN_FRICTION tuned 3.0 → 5.0), upright + gait restored, trip().
- Non-hosted regressions PASS (smoke_enemy_body, smoke_debug_overlay).
- Hosting regressions (smoke_enemy, smoke_tail_damage, smoke_punch,
  smoke_walljump…) queued — port 7777 held by the operator's live
  play session.
