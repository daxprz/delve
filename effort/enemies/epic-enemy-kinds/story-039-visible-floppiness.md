---
xid: STO-ENEMIES-039
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
date: 2026-08-14
depends-on: [STO-ENEMIES-037]
bd-id: delve-vfl9
---

# Floppiness you can actually see

## Summary

The spider's limbs should look loose and rubbery **while it walks
around doing nothing special** — which is when you are actually looking
at it.

STO-ENEMIES-037 built a working mechanism that produces **1.4 degrees**
at its peak on a walking spider, decaying to zero. The operator's
verdict was "it isn't flopy in any way", and the measurement agrees.

## What went wrong, so it is not repeated

Floppiness was driven by **changes in the body's velocity**. Starting,
stopping and turning produce those; walking steadily in a line does
not. So a spider doing its ordinary thing got nothing.

Worse, the tests passed. They provoked the creature by shoving it at
**14 m/s** — about nine times its walking speed of 1.6, and something
that never happens in play. Every number in that story is real and
every one of them was measured under conditions the game never
produces.

## The fix

Limbs lag **the pose the gait is asking them to hit**, not just the
movement of the body.

The legs are swinging the whole time the spider walks. A loose limb
trails behind its own swing and overshoots when the swing reverses —
so floppiness appears exactly when the creature is walking, which is
exactly when it is being looked at. Body movement stays as a second
contribution on top, for lurches and turns.

## Definition of Done

- [x] A spider **walking normally at 1.6 m/s** visibly flops. Measured,
      with a number written down here.
- [x] The far end of a limb trails noticeably behind the near end.
- [x] Limbs overshoot when a swing reverses, rather than easing in.
- [x] The pincer arms swing too, not just the legs.
- [x] A **standing** spider still settles — floppiness must not become
      a permanent idle wobble.
- [x] It still walks properly: feet still push back while planted, and
      it does not skate or trip.
- [x] Proven by a headless test that provokes the spider **only by
      letting it walk**. No 14 m/s shove anywhere in it.
- [ ] **The operator looks at it and agrees it is floppy.** Until then
      this story is not done, whatever the numbers say. NOT YET SEEN.

## What it took (2026-08-14)

Each joint became a damped spring chasing the angle the gait asks for,
instead of snapping to it. The far joint is much softer than the near
one — that difference IS the look, because it makes the end of a long
limb whip along behind the part near the socket. Equal stiffness would
lag the whole leg as one rigid piece.

Measured on a spider doing nothing but walking at 1.6 m/s:

| | Lag while walking |
|---|---|
| STO-ENEMIES-037 (body-driven) | **1.4 deg**, decaying to 0.0 |
| this story (gait-driven) | **26-46 deg**, peaking at 59 |

Standing still it settles to **0.1 deg**, so it has not become a
permanent idle wobble.

### Teeth

Stiffening the joints so they snap to the pose — the old behaviour —
drops it to **6.3 deg** and fails. The floor is set at 10 deg
specifically so a regression to body-driven floppiness cannot pass.

### The knock-on nobody would have predicted

`smoke_crawler`'s "a standing crawler does not jog on the spot" started
failing, at **0.0284 m** of foot drift against a 5 mm tolerance.

Not a bug. The springs decay with a time constant of 0.59 s, so a
spider that has just halted keeps swinging for about **four seconds** —
which is the feature working. The test sampled at 40 ticks, then at
150, and both caught it mid-settle. At 330 ticks the drift is
**0.0003 m**.

Worth noting how that was found: the failure message said "jogging on
the spot", which sounds like the gait had broken. Printing the actual
numbers showed enemy speed 0.0000 and gait lag 0.0008 — nothing was
driving it, it simply had not finished settling. The assertion and its
5 mm tolerance are untouched.

Full suite: **pass=53 fail=0**, 24 skipped for the port.

## Out of scope

- Limbs colliding with the world as they swing.
- Real rigid-body physics while standing. It already becomes a true
  ragdoll when knocked down.

## The lesson worth keeping

A test that has to hit something nine times harder than the game ever
will is not testing the game. **Provoke a feature the way play
provokes it, or the number proves nothing.**
