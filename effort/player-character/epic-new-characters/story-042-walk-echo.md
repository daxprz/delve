---
xid: STO-CHARACTER-042
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-mtq
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Walking rings the room clearly, not just sprinting

## Summary

Walking already emitted echoes, but they were small and dim — half
the brightness of a sprint and roughly half the reach — so at walking
pace the room barely registered and the Sniper felt blind unless
something was running. Tuned so a walk gives a proper ripple:

- audible threshold `MIN_MOVE_SPEED` 0.8 → 0.35 m/s
- base reach `PULSE_RADIUS_BASE` 3.0 → 6.5 m (max 14 → 16)
- new `STRENGTH_FLOOR` 0.72, so the quietest audible movement is
  still bright rather than a flicker
- spreading loss softened 0.75 → 0.55, so the outer edge of a walk's
  ripple stays readable

Speed still matters — a sprint reaches much further and burns
brighter — it just no longer decides whether you can see at all.

## Definition of Done

- [x] Walking pace emits a wave.
- [x] A walk's wave is bright (strength ≥ 0.7), not a faint flicker.
- [x] A walk's wave reaches across a room (≥ 6 m).
- [x] A sprint still reaches noticeably further than a walk.
- [x] All existing echo rules unchanged (only the room is drawn,
      distance fade, waves expire to black).

## Out of scope

- Different echo strength per creature size/weight — a heavy enemy
  arguably ought to be louder than a light one. Worth doing once the
  Sniper's own play style is designed.

## Verification notes (2026-08-07)

- Measured before: a 3 m/s walk peaked at 134 marks with strength
  0.50 and 5.7 m reach. After: 195 marks, strength 0.72, 8.3 m reach —
  while a 9 m/s sprint still reaches 14.6 m.
- 21/21 PASS in `tests/smoke_sniper_echo.gd`, which now asserts the
  walk case directly so it can't silently regress into invisibility.
