---
xid: STO-CHARACTER-009
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-o70
tasks: 3
complete: 3
---

# A powerful enough punch makes a shockwave

## Summary

When a punch is **powerful enough** (enough momentum behind it), it
makes a **shockwave** at the impact point — a burst that pushes
everything nearby away, with a quick expanding ring you can see.

## Definition of Done

- [x] A punch above a power threshold spawns a shockwave; a weak one
      doesn't.
- [x] The shockwave shoves nearby physics bodies radially outward.
- [x] There's a visible expanding ring effect that cleans itself up.

## Verification notes (2026-08-03)

- `scripts/shockwave.gd` (`Shockwave`): on spawn it sphere-queries the
  physics space within `RADIUS` and applies a radial impulse (scaled by
  `power`) to every RigidBody, plus an expanding+fading `TorusMesh`
  ring that frees itself after `LIFETIME`.
- `mechanical_arms.gd` spawns one when `power >= SHOCKWAVE_POWER` (14).
- `tests/smoke_punch.gd`: **RESULT: PASS** — the weak punch (power 6)
  made no shockwave; the powerful punch (power 21) spawned one that
  pushed the box.

## Out of scope

- Shockwave damaging enemies (no enemies yet) and screen-shake / sound.
