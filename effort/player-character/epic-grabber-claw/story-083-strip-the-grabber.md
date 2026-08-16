---
xid: STO-CHARACTER-083
parent: ./epic.md
kind: story
effort: character
size: M
status: draft
date: 2026-08-16
depends-on: []
bd-id: delve-y3aw
---

# Strip the Grabber back to nothing

## Summary

Take the Grabber back to a body with two mechanical arms and **no
abilities at all**. Zip, throw, pull, piston, block and punch mode all
come out.

This is first because the new controls need the old keys: Q was the zip
and E was the arm-mode toggle, and both are wanted for the claw.

## Removing is not deleting

Every story being switched off is marked **removed** and keeps its
text — what it was for, what it measured, what bugs it found. delve
already does this: the Guardian and the Builder were dropped and their
stories are still there, marked abandoned.

The reason is not sentiment. Those stories record things learned the
hard way — that a punch's power should come from momentum, that a
grabbed crate must not be teleported, that `has_method` beats a null
check — and that knowledge outlives the feature.

## Definition of Done

- [ ] The Grabber's ability list is empty.
- [ ] Zip, throw, pull, piston, block and punch mode do nothing for it.
- [ ] Q, E, F and C do nothing for the Grabber any more.
- [ ] **Nothing else breaks.** Block and dodge are used by other
      characters in places; removal must be from the GRABBER, not from
      the game.
- [ ] The removed stories are marked removed, with their text intact.
- [ ] Proven by a headless test that presses each old key and checks
      nothing happens.

## Out of scope

- Removing the mechanical arms themselves. The claw needs them.
- Removing the fingers.
