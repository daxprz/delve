---
xid: STO-CHARACTER-032
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-90h
shipped: 2026-08-07
tasks: 6
complete: 6
---

# Runner: hold Space to charge a pounce

## Summary

The Runner can **pounce**: holding **Space** on the ground coils it —
the camera dips into a crouch and it holds still — and releasing
springs it forward and up, scaled by how long you charged (up to 0.9 s
for full power). A tap of Space is still an ordinary jump. Pounce
momentum is preserved through the arc (like a wall-jump launch), so
you keep flying instead of being damped back to walk speed; you can
still steer gently mid-air. Driven by a `pounce: true` flag in the
character def, so other characters are unaffected, and the Runner's
wall-jump still works (only its GROUND jump becomes the pounce).

## Definition of Done

- [x] Only the Runner has pounce (character-def flag).
- [x] Tap Space = normal jump; hold = charge; release = launch.
- [x] Charging visibly crouches (camera dips) and holds you still.
- [x] A full pounce travels far further than a jump and keeps its
      momentum through the arc.
- [x] Runner's wall-jump is unaffected.
- [x] `tests/smoke_pounce.gd` passes headless (8 checks, non-hosted).

## Out of scope

- Pounce damage / tackling an enemy on impact (a natural follow-up).
- A charge-strength HUD meter.

## Tuning log

- 2026-08-07: **Power halved** at the operator's request —
  `POUNCE_FORWARD` 15.0 → 7.5, `POUNCE_UP` 1.25 → 1.12. A full-charge
  pounce now launches at 9.6 m/s and travels **9.6 m** (was 16.4 m/s
  and 21.5 m). Still far beyond a plain jump; less map-crossing.

## Verification notes (2026-08-07)

- 8/8 PASS: full charge launches at 16.4 m/s and travels **21.5 m**
  vs 0.0 m for a tap; camera dips 1.60 -> 1.41 while charging.
- Two bugs found and fixed during the build:
  1. gating the whole jump block on `not _can_pounce` would have
     killed the Runner's wall-jump — only the ground branch is
     replaced now;
  2. `_pouncing` was cleared on the very tick it was set (still
     touching the floor, button already released), so the momentum
     preservation never applied and the pounce died at 4 m. Now it
     clears only once back down (`is_on_floor() and velocity.y <= 0`).
