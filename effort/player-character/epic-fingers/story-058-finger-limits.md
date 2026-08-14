---
xid: STO-CHARACTER-058
parent: ./epic.md
kind: story
effort: character
size: M
status: draft
date: 2026-08-13
depends-on: [STO-CHARACTER-057]
bd-id: delve-rze
---

# Fingers bend like real fingers

## Summary

Fingers must bend the way fingers actually bend. They **cannot fold
backwards** past straight, and they **cannot pass through each
other**.

Without this, a procedurally-curled hand looks instantly wrong: joints
hyperextend into a shape no hand makes, and the fingers slide through
one another when they close.

## Definition of Done

- [ ] A finger cannot bend backwards past straight, however hard
      something pushes it.
- [ ] A finger cannot curl past a closed fist — no folding through
      the palm.
- [ ] Neighbouring fingers do not pass through each other when they
      close.
- [ ] The thumb does not pass through the fingers.
- [ ] The limits hold in **every** mode — grabbing, clenched, and
      hanging loose.
- [ ] Proven by a headless test that drives the curl beyond both ends
      of its range and checks the fingers stay in a hand shape.

## Out of scope

- Full physical collision between fingers and the world. Fingers keep
  out of *each other*; the hand as a whole already collides.

## Depends on

**STO-CHARACTER-057** — there must be fingers before they can be
limited.
