---
xid: STO-CHARACTER-041
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-3h9
shipped: 2026-08-07
tasks: 6
complete: 6
---

# Echo renders as expanding waves that dim as they spread

## Summary

The Sniper's echo was drawn as a single flash: every surface a pulse
touched lit up at once and faded together. Now each pulse is a real
**expanding wave**. A pulse records how far each surface mark is from
its origin, and a wavefront sweeps outward at ~11 m/s: a surface is
**dark until the wave reaches it**, **brightest as the front passes**,
then trails off behind. The wave also **dims as it expands**, since
the same sound is spread over a bigger and bigger shell — so distant
walls are sketched faintly even when the pulse was loud.

The result is a ripple of light rolling outward from whatever moved,
rather than a room-shaped flashbulb.

## Definition of Done

- [x] Each pulse renders as a wavefront expanding over time, not an
      instant flash.
- [x] A surface is dark before the front arrives.
- [x] A surface is brightest at the front and dims behind it.
- [x] The wave weakens the further it spreads from its origin.
- [x] Waves expire once the front has swept past everything, and the
      world returns to black.
- [x] Existing echo rules still hold: only the room is drawn (never
      the creature), and everything fades with distance from the
      Sniper.

## Out of scope

- Sound (still purely visual).
- Waves bending round corners / bouncing — the pulse is line-of-sight
  raycasts, so a wall's far side stays dark. Arguably correct for
  echolocation, and worth revisiting if it plays badly.

## Verification notes (2026-08-07)

- 17/17 PASS in `tests/smoke_sniper_echo.gd`.
- Wave shape: brightness 0.00 before the front arrives, 0.40 at the
  front, 0.00 well behind it; spreading loss takes a front at 2 m
  from 0.85 down to 0.32 by 9 m.
- 10 live wavefronts tracked simultaneously while things were moving;
  all expired to zero once the world went quiet.
- Test lesson: the test had been reaching into the node's private
  `_marks` field, which silently became Nil when the storage changed
  to per-pulse — the test then looped forever instead of failing.
  Replaced with an `all_marks()` accessor.
