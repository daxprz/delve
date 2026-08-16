---
xid: STO-CHARACTER-008
parent: ./epic.md
kind: story
effort: character
size: L
status: removed
date: 2026-08-03
depends-on: []
bd-id: delve-511
tasks: 3
complete: 3
---

# Punch power scales with the player's momentum

## ⛔ REMOVED from the Grabber (2026-08-16)

The Grabber was remastered into a claw-machine claw
(EPI-CHARACTER-GRABBER-CLAW) and every one of its abilities was taken
out at the operator's request — four abilities, four keys and seven
unfinished piston stories traded for one idea a child can describe in
a sentence.

**This story is kept, not deleted**, the way the Guardian and Builder
were. What it measured and the bugs it found outlive the feature.

## Summary

In punch mode, clicking throws a punch whose **power grows with the
player's momentum** (their current speed). So you swing on the grapple
to build speed, switch to punch mode, and hit hard. The punch knocks
back whatever it connects with.

## Definition of Done

- [x] A punch's power = a base amount + the player's speed.
- [x] Punching a physics body knocks it back, harder the faster you go.
- [x] The fist visibly jabs forward when you punch.

## Verification notes (2026-08-03)

- `mechanical_arms.gd` `punch(i)`: `power = PUNCH_BASE_POWER + speed *
  PUNCH_MOMENTUM_SCALE`; a short crosshair ray finds the target;
  RigidBodies get `apply_central_impulse(aim * power)`. The fist jabs by
  giving the fingertip verlet velocity (`PUNCH_THRUST`).
- `tests/smoke_punch.gd`: **RESULT: PASS** — a slow punch moved the box
  0.98 m, a fast punch moved it 7.13 m (power scales with momentum).

### Change 2026-08-03 — must connect + spammable

- [x] A punch now only **activates on an actual hit** — a whiff through
      empty air applies no knockback and makes no shockwave (the
      shockwave is gated on `connected and power >= threshold`).
- [x] Punches are **spammable**: holding the button calls `try_punch`
      each frame, firing repeatedly on a short cooldown
      (`PUNCH_COOLDOWN` 0.12 s) instead of one-per-click.
- `tests/smoke_punch.gd` updated: **RESULT: PASS** — an empty-air punch
  makes no shockwave; a connecting slow vs fast punch scales (0.93 vs
  6.78 m); and `try_punch` fires then reports cooldown.

## Out of scope

- Real enemies to hit (punches currently affect the box / physics
  bodies) — a future effort. Damage/health system too.
