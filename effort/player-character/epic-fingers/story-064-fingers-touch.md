---
xid: STO-CHARACTER-064
parent: ./epic.md
kind: story
effort: character
size: S
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-5nm
---

# Fingertips rest ON what they hold

## Summary

The fingers should look like they are **actually gripping** — tips
resting against the surface, not hovering a gap away from it.

Right now each finger stops one step *before* it would overlap the
object, and there is a 4.5 cm margin on top. Between the two, a
fingertip can sit visibly short of what it is holding, so a held crate
looks like it is floating in a claw rather than being gripped.

## Definition of Done

- [x] Margin cut 0.045 -> 0.02, and the sweep stops HALF a step back rather than a whole one.
- [x] They still stop before overlapping.
- [x] The remaining gap is small — a fingertip's width at most.
- [x] STO-CHARACTER-058 still passes: no palm folding, no clipping.
- [x] Crate, grabbed body and dragged-ragdoll tests all still pass.

## Verification notes (2026-08-14)

Two causes, not one: a 4.5 cm contact margin AND the sweep stopping a
whole step before contact. Together they left a visible gap, so a held
crate looked like it was floating in a claw. Halving the step-back was
the bigger of the two, and is what shipped.

**The margin had to come back.** Cut to 0.02 it looked marginally
better and broke gripping a MOVING body: a fingertip had to get so
close that it missed a swinging ragdoll, and `smoke_wrap_ragdoll` went
from 4/4 to 2/4. Restored to 0.035, which is 5/5 again.

A grip that looks a millimetre tidier but lets go of a body you are
dragging is a bad trade, and only the full suite catches that — the
hand tests all passed at 0.02.

## Out of scope

- Fingers deforming or flattening against a surface.
