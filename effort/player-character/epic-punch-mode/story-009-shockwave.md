---
xid: STO-CHARACTER-009
parent: ./epic.md
kind: story
effort: character
size: M
status: removed
date: 2026-08-03
depends-on: []
bd-id: delve-o70
tasks: 3
complete: 3
---

# A powerful enough punch makes a shockwave

## ⛔ REMOVED from the Grabber (2026-08-16)

The Grabber was remastered into a claw-machine claw
(EPI-CHARACTER-GRABBER-CLAW) and every one of its abilities was taken
out at the operator's request — four abilities, four keys and seven
unfinished piston stories traded for one idea a child can describe in
a sentence.

**This story is kept, not deleted**, the way the Guardian and Builder
were. What it measured and the bugs it found outlive the feature.

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
