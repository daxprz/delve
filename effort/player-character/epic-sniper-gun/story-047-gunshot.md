---
xid: STO-CHARACTER-047
parent: ./epic.md
kind: story
effort: character
size: L
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-9lo
shipped: 2026-08-07
tasks: 8
complete: 8
---

# The rifle: a long shot whose bang lights the room

## Summary

The Sniper's rifle. A single hitscan shot reaching 140 m that does
55 damage and knocks the target down — the first weapon in delve that
works at range, and the first reason to want distance rather than
close it.

**The bang is the point.** Per the operator's design decision, firing
floods the area with one enormous echo wave (45 m, ~110 rays, far
beyond any footstep). The Sniper is blind, so *the gunshot is how you
look around* — and it tells everything exactly where you fired from.
A second, smaller echo bursts where the bullet lands, so you can read
what you hit at the far end of a room. A miss still lights you up: you
gave your position away for nothing.

Slow and deliberate — a 1.6 s reload with a HUD bar — so it can't be
spammed as a flashlight.

## Definition of Done

- [x] The Sniper (and only the Sniper) has a gun.
- [x] A shot reaches across the map and does serious damage at range.
- [x] A hit knocks the target down.
- [x] Firing floods the room with a big echo wave — far more than a
      footstep.
- [x] The impact point emits its own smaller echo.
- [x] A miss still lights the room (the trade-off is real).
- [x] Reload cooldown, shown on the HUD.
- [x] `tests/smoke_sniper_gun.gd` passes headless (12 checks).

## Out of scope

- Ammo and reloading by hand (cooldown only).
- A scope / zoom.
- Sound — as ever, this is the visual representation of hearing.

## Design note

Aiming was the open question for this epic: how does a blind character
aim? The operator chose "the gunshot lights the room" over a sonar
scope, a target-revealing ping, or softening the never-outline-a-
creature rule. It is the riskiest of the four and the only one that
costs you something to use — which is what makes the Sniper tense to
play rather than simply strong.

## Verification notes (2026-08-07)

- One shot produced **102 new echo marks** (a footstep produces a
  couple of dozen), reaching 14 m at the sampled instant as the wave
  expanded.
- A hit at **40 m** took the target 60 → 5 hp and ragdolled it.
- Reload 1.6 s; a miss still lit the room.
