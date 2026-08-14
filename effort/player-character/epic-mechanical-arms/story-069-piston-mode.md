---
xid: STO-CHARACTER-069
parent: ./epic.md
kind: story
effort: character
size: S
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-b5ki
---

# The piston is a third arm mode, cycled with E

## Summary

The piston is a **mode**, like grabbing and punching — not a separate
toggle sitting on top of them.

`E` cycles **GRAB -> PUNCH -> PISTON -> GRAB**. While the piston is
on, the arms neither grab nor punch: they are one shaft.

## Why it needed changing

STO-CHARACTER-067 put the piston on `F`, independent of the arm mode.
So the arms could be in grab mode AND piston mode at once — gripping
something and pistoning with the same limbs. A mode that sits on top
of another mode is not a mode.

## Definition of Done

- [x] `E` cycles through all three modes, in order.
- [x] Piston mode is reachable by pressing the real `E` key —
      verified as `[0, 1, 2, 0, 1, 2]`.
- [x] Changing mode drops anything held, so nothing is carried
      through.
- [x] The arms look different in piston mode (cold blue-white, against
      punch mode's warm orange).
- [x] `set_punch_mode()` still works for older callers and tests.

## Verification notes (2026-08-14)

The bug was one line and would have been invisible from the code:
`E` called `set_punch_mode(not _punch_mode)`. **Flipping a bool can
only ever reach two states**, so the third mode existed and was
unreachable.

Caught by pressing the REAL key in a test and printing which modes
came back — `[0, 1, 0, 1, 0, 1]`. The earlier piston test called
`toggle_piston()` directly and so proved nothing about whether a
player could ever get there.

That is the same lesson as the operator reporting "it still isn\'t in
the game" while every test passed: a function working is not the same
as a key working.
