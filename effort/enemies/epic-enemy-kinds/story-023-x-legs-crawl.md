---
xid: STO-ENEMIES-023
parent: ./epic.md
kind: story
effort: enemies
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-0fd
---

# X-shaped legs and a real crawling gait

## Summary

Two changes to how the spider is built and how it moves:

- **Legs shaped like the end of an X.** The middle segment rises
  STEEPLY rather than reaching outward, so the knee is a sharp high
  peak and the leg makes a narrow inverted V.
- **It crawls.** Feet PLANT on the ground and push the body along,
  then lift and swing forward — instead of sliding back and forth
  through the floor.

## Definition of Done

- [x] The middle segment rises steeply, making a sharp knee peak.
- [x] Feet plant and sweep back during stance, then lift to return.
- [x] Feet still reach the ground through the whole stride.
- [x] It still towers, still walks in diagonal pairs, still ragdolls.

## Verification notes (2026-08-14)

**The gait was a sine wave**, which slides a foot forward and back
through the floor the entire time. A leg that is CARRYING the creature
has to stay put while it pushes. It is now split:

| phase | what the leg does |
|---|---|
| 0.0 - 0.6 | planted, sweeping steadily BACK |
| 0.6 - 1.0 | lifted, returning forward fast |

Longer on the ground than in the air, which is what makes it a walk
rather than a prance.

**That immediately broke the feet.** They ended up **0.27 m in the
air**, and the reason is worth keeping: the body height is derived
from the leg at REST, but a walking leg is swung forward or back by up
to STEP_REACH — and a tilted leg does not reach as far down. The
height now includes that shortening.

A tidy example of one change quietly invalidating an assumption made
by another: the derived-height maths was correct, its input was not.

Without foot IK the feet still rise and fall slightly across a stride.
That is a real visual imperfection, and the honest fix if it shows is
proper IK rather than a looser tolerance.
