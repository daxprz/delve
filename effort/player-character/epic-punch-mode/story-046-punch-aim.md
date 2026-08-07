---
xid: STO-CHARACTER-046
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-gqn
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Punches aim up and down with the camera

## Summary

Punches now go **where you look**, up and down included.

`_reach_point` took the player BODY's facing and flattened it
(`fwd.y = 0`), but pitch lives on the camera, not the body — so every
punch came out dead level no matter where you aimed. It now uses the
camera's aim direction, and the knockback is applied along that same
aim, so an upward punch genuinely launches an enemy into the air.

Punch power was also raised again: it now floors even the sturdiest
procedural build. The previous values could damage a heavy, stable
enemy repeatedly without ever knocking it down.

## Definition of Done

- [x] Aiming up raises the punch; aiming down lowers it.
- [x] An aimed punch still connects and damages.
- [x] An upward punch launches the enemy UPWARD, not just forward.
- [x] A punch knocks down even the sturdiest possible build.
- [x] `tests/smoke_punch_aim.gd` passes headless (5 checks,
      non-hosted).

## Out of scope

- Aiming the GRAB up and down — that already uses the camera ray.
- Separate uppercut/overhead animations; the arm simply reaches where
  you aim.

## Verification notes (2026-08-07)

- Fist height: 1.33 m level, **2.87 m** aiming up, **0.06 m** aiming
  down — a 2.81 m spread.
- Uppercut launches the held torso at **vy 3.5 m/s**.
- Found while testing: the punch was connecting and dealing damage
  (60 → 40 → 13 hp) yet never knocking down, because that enemy had
  rolled a sturdy build and the impulse (11.1) fell short of the ~14
  such a body needs. Base/scale raised to 6.0 + 1.6/m/s, and the test
  now FORCES the worst-case build so this can't pass by luck of the
  random seed.
