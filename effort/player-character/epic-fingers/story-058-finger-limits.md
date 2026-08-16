---
xid: STO-CHARACTER-058
parent: ./epic.md
kind: story
effort: character
size: M
status: superseded
date: 2026-08-13
depends-on: [STO-CHARACTER-057]
bd-id: delve-rze
---

# Fingers bend like real fingers

## ⛔ SUPERSEDED by the claw (2026-08-16)

The Grabber's hands became a three-prong claw-machine claw
(STO-CHARACTER-087), and the Grabber was the **only** character with
mechanical arms — so the five-finger hand no longer exists anywhere in
delve.

**Kept, not deleted.** What this story measured and the bugs it found
are still true of hands, and the claw reuses the machinery underneath
it: the same nested joint chain, the same curl driver, the same wrap.
The prongs are built as digits precisely so none of that had to be
rewritten.

## Summary

Fingers must bend the way fingers actually bend. They **cannot fold
backwards** past straight, and they **cannot pass through each
other**.

Without this, a procedurally-curled hand looks instantly wrong: joints
hyperextend into a shape no hand makes, and the fingers slide through
one another when they close.

## Definition of Done

- [x] A finger cannot bend backwards past straight — a curl of -5
      leaves it exactly straight.
- [x] A finger cannot curl past a closed fist — a curl of 9 changes
      nothing, and no segment enters the palm at any curl.
- [x] Neighbouring fingers keep a 0.0276 m gap at every curl.
- [x] The thumb does not pass through a finger.
- [x] Checked across the whole curl range (0, 0.25, 0.5, 0.75, 1).
- [x] Proven by a headless test (16 checks).

## Verification notes (2026-08-13)

`tests/smoke_finger_limits.gd`, 16 checks, measuring **positions in
world space** — so it fails if the geometry drifts even while the
constants still look sensible.

Both faults the operator predicted were real, and both were found by
measuring rather than looking:

| what was asked for | what was actually there |
|---|---|
| "can't bend too far back" | at full curl the fingertip sat **inside the palm block** — y -0.101 against a palm spanning +/-0.20 |
| "can't clip into each other" | the four fingers **overlapped by 2.2 mm** — 0.0728 spacing against 0.075 thickness |

Fixed by thinning the fingers (0.075 -> 0.062), widening the spread
(0.26 -> 0.32), dropping the knuckles below the palm centre, and
cutting the total curl from 212 to 155 degrees.

**The thumb took three attempts**, each guided by a measurement rather
than a guess:

1. Buried in the middle of the palm — its base was inside the block.
2. Moved to the palm's side: still swept **from x -0.22 to -0.04**,
   straight through the hand, because its tilted curl plane cut across
   the palm.
3. Moved below the palm's lower face and given its own smaller curl
   range (0.42 of a finger's). Real thumbs curl less than fingers, so
   this is anatomy rather than a fudge — and it stops the tilted plane
   carrying the tip back up into the palm.

One check is deliberately scoped: the **base knuckle** is excluded
from the palm test, because it is the attachment and a real thumb's
base sits inside the palm too. What must never happen is a finger
FOLDING through the hand, and every segment past the base is checked.

Teeth-checked by restoring the old geometry: it reports
*"Pointer is inside the palm"* and *"gap -0.0022 m"* — the operator's
two predictions, in the failure output.

## Out of scope

- Full physical collision between fingers and the world. Fingers keep
  out of *each other*; the hand as a whole already collides.

## Depends on

**STO-CHARACTER-057** — there must be fingers before they can be
limited.
