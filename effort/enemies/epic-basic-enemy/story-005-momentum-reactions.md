---
xid: STO-ENEMIES-005
parent: ./epic.md
kind: story
effort: enemies
size: M
status: shipped
date: 2026-08-06
depends-on: []
bd-id: delve-kzq
shipped: 2026-08-06
tasks: 5
complete: 5
---

# Momentum-based reactions from the procedurally-generated build

## Summary

Hit reactions become momentum physics driven by each enemy's
procedurally-generated build (STO-ENEMIES-005, extends 004). From the
body's variation scales, each enemy derives a physical character:
mass (bulk² × build mix, clamped 0.75–1.5), center-of-mass height
(legs + torso) and stability (bulk vs height). All hits are momentum
transfers — `dv = impulse / mass` — so the same punch launches a
lightweight and barely rocks a heavyweight. The knockdown threshold
scales with stability; tumble spin comes from angular momentum
(total horizontal speed × lever arm / m·h², sweeps get a 1.6× lever),
so an enemy's OWN momentum feeds its tumble — trip a sprinter and it
cartwheels. Heavier builds stay down and get up slower.

## Definition of Done

- [x] Mass/stability/center-of-mass derive from the generated body;
      they differ across individuals.
- [x] dv × mass recovers the applied impulse (true momentum transfer);
      the same hit visibly moves different builds differently.
- [x] Tumble spin scales with total speed at knockdown (own momentum
      counts); trips (low lever) spin harder than body blows.
- [x] Knockdown threshold and down/get-up times scale with the build.
- [x] `tests/smoke_enemy_reactions.gd` passes headless (11 checks).

## Out of scope

- Player-side momentum model (characters already have per-class
  speed/jump; unifying mass is a later design question).
- Enemy-vs-enemy collisions transferring momentum.

## Verification notes (2026-08-06)

- 11/11 PASS. Sampled builds: masses 0.78 / 1.37 / 0.95 — the light
  one flew 12.1 m from a |10| impulse (dv 12.8), spin clamps at 14;
  sprint-trip spun 14.0 vs 5.6 standing. dv×m recovered 2.00 exactly
  for two different builds.
- `smoke_enemy_body` regression PASS. Hosting regressions still
  queued behind the operator's play session (port 7777).
