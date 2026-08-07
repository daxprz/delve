---
xid: STO-CHARACTER-051
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-8wr
shipped: 2026-08-07
tasks: 7
complete: 7
---

# Echo palette: blue world, red enemies, green friends, dots not crosses

## Summary

The Sniper's view is now colour-coded by **what a thing is**, with the
shade carrying **how long ago you learned it**:

| | colour |
|---|---|
| ground and walls | shades of **blue** |
| enemies | shades of **red** |
| other players | shades of **green** |

Everything darkens toward black as it ages and then disappears.

**Rays now strike creatures**, not just the wall behind them, for both
the lidar and for sound — so an enemy is a red cluster and a friend is
a green one. Only whatever *made* a noise is skipped, so a footstep
does not simply paint its own owner.

Marks are drawn as **simple dots** rather than little crosses: at 600
rays a sweep the crosses smeared together, while points read as a
proper point-cloud of the room.

The Sniper's camera also gets a **pure black environment**. Culling
the world still left the sky drawn behind it, so "blind" was really a
bright empty backdrop.

## Definition of Done

- [x] World marks blue, enemies red, other players green.
- [x] Shade darkens with age, to black, then gone.
- [x] The three hues are distinguishable at a glance.
- [x] Rays hit creatures; every creature mark lands ON the creature.
- [x] Dots, not crosses.
- [x] The Sniper's background is genuinely black.
- [x] `tests/smoke_echo_vision.gd` passes (19 checks).

## Supersedes an earlier decision

STO-CHARACTER-040 recorded the operator's choice that a sound should
outline **"only the walls around a mover, never the mover itself"** —
deliberately spookier. **That is now reversed**: creatures are marked
directly, in their own colours. The reversal is intentional and was
requested after playing; the original reasoning is left in
STO-CHARACTER-040 rather than rewritten, so the history of the design
still reads honestly.

STO-CHARACTER-049's "enemies show red on the lidar" is absorbed here
and extended to sound and to other players.

## Out of scope

- Distinguishing individual friends from each other.
- Colour-blind alternatives to red/green, which is the obvious
  accessibility gap in this scheme.

## Verification notes (2026-08-07)

- Palette asserted at both ends of each ramp: world (0.35, 0.62,
  1.00) blue fading to 0.10; enemies (1.00, 0.22, 0.22); friends
  (0.30, 1.00, 0.42).
- With an enemy 6 m away, a sweep put **3 red marks on it and 325
  blue on the room**, and every red mark was verified to be ON the
  creature (0 stray).
- Test lesson: the first version of that check failed because a
  chasing enemy walks away from its own dots — marks record where a
  thing WAS. The enemy is frozen for the measurement.
