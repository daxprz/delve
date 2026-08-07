---
xid: STO-CHARACTER-031
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-bk3
shipped: 2026-08-07
tasks: 4
complete: 4
---

# Punch mode: arms hang at your sides, no raised guard pose

## Summary

Pressing **E** (punch mode) no longer parks both fists in a raised
guard pose in front of the chest. The Verlet arms simply hang at the
player's sides under gravity — punch mode is now invisible at rest —
and a fist only sticks straight out while the punch button is HELD
(the ram pose), dropping back down on release. Grab mode and the
warm fist glow that marks punch mode are unchanged.

## Definition of Done

- [x] In punch mode at rest, the fists hang well below the shoulders.
- [x] Holding the punch button still extends the fist out in front;
      releasing drops it back down.
- [x] Grab behaviour, ram damage and mode-switch glow unchanged.
- [x] `tests/smoke_arm_rest.gd` passes headless.

## Out of scope

- A dedicated idle arm animation (the arms are pure physics at rest).
- Any change to grab mode's reach/pull behaviour.

## Verification notes (2026-08-06)

- `smoke_arm_rest` 4/4: fist rests at y=0.23 with the shoulder at
  y=1.40; holding the button raises it to 1.36 and reaches 1.96 m
  forward; release drops it to 0.06. Written non-hosted (direct
  player instancing) specifically so it runs while the operator has
  a game open holding port 7777.
- Removed the now-dead `_guard_point()` and its GUARD_FORWARD/
  GUARD_HEIGHT constants.
- Hosting-based arm regressions (smoke_punch, smoke_arms,
  smoke_arm_solid, smoke_grab) are QUEUED — they need port 7777.
