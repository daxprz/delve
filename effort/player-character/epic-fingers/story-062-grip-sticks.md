---
xid: STO-CHARACTER-062
parent: ./epic.md
kind: story
effort: character
size: M
status: draft
date: 2026-08-13
depends-on: []
bd-id: delve-2hi
---

# Each finger finds the surface and keeps hold as you move

## Summary

Every finger works out **for itself** how far to close, by curling
until it actually meets the thing you are holding — and it works it
out **again every tick**, so as you move, turn and look around, the
hand keeps its grip on the object instead of holding a pose decided at
the moment you grabbed it.

This is the difference between a hand that *is* holding something and
a hand that was posed once and left. STO-CHARACTER-059 closes all five
fingers by the same amount, from the object's overall size. That is
fine standing still, and wrong the moment anything moves: fingers on
the near side should close less than fingers reaching round the far
side, and all of it changes as the object shifts in your grip.

Procedurally generated in the same sense as the rest of delve: nothing
authored, no per-object hand poses. Each finger sweeps its own curl
until its fingertip meets the object's surface, and stops there.

## Definition of Done

- [x] Each finger has its **own** curl, not one shared value.
- [x] A finger stops when its tip reaches the object's surface.
- [~] Fingers at different distances curl by different amounts — TRUE
      while moving and turning, but NOT yet distinguishing a big
      object from a small one. **This story is not finished.**
- [x] Recomputed every tick: moving re-fits 3 of 5 fingers, turning
      re-fits 4 of 5.
- [x] Moving the object within the grip changes the curls.
- [x] Still obeys STO-CHARACTER-058 at every point in the sweep.
- [x] Letting go opens the hand again.
- [ ] Proven by a headless test that moves things and checks the
      curls actually change.

## Where this got to (2026-08-13) — NOT finished

Working: each finger finds the surface for itself, and the grip
re-fits every tick as things move (3 of 5 fingers change when the
object shifts, 4 of 5 when the player turns).

**Still failing:** `smoke_finger_grip` reports *"a BIGGER object
leaves the fingers LESS curled (1.00 big vs 1.00 small)"* — both close
fully, so a crate and a small block feel the same. The per-finger
sweep works, but for those two the fingertips pass the object without
registering it. Left failing on purpose rather than loosening the
check, because that check IS the story.

### What the arm length was hiding

Two faults only became visible once fingers existed:

- The carry point was **2.40 m** from the camera while the arm reached
  **2.02 m** to the knuckles, so a held object floated **0.75 m beyond
  the fingertips**. Nothing looked broken until fingers needed a
  surface to close on.
- Easing the hand toward its target at 0.18 never arrived — gravity
  drags the chain down every tick, so it settled short. Carrying now
  pulls at 0.55.

The operator chose to lengthen the arms (1.20 + 1.05, reaching 2.59 to
the knuckles) rather than give up either eye-level holding or the
wrapping. That let the hand and the object share one target, which is
what fixed the eye-level tests.

Pinning the hand hard to its target was tried and **reverted** — it
made things worse, ending 0.76 m from the eye instead of 1.75.

## Out of scope

- Real physical contact forces between fingers and objects. The
  fingers find the surface and stop; they do not push it.

## Depends on

**STO-CHARACTER-057 / 058 / 059** — all shipped.
