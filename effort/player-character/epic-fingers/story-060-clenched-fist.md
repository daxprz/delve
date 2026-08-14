---
xid: STO-CHARACTER-060
parent: ./epic.md
kind: story
effort: character
size: S
status: draft
date: 2026-08-13
depends-on: [STO-CHARACTER-057, STO-CHARACTER-058]
bd-id: delve-c9v
---

# Punch mode clenches the fist

## Summary

Press `E` for punch mode and the fingers **clench into a fist** — all
of them, fully closed, held there while you are in punch mode. Switch
back to grab mode and they open again.

The Grabber already changes what the hands *do* between the two modes
(STO-CHARACTER-007); this makes the hands finally *look* like what
they are doing.

## Definition of Done

- [x] Punch mode curls every finger fully closed (1.00).
- [x] The thumb closes with them, at its own smaller range.
- [x] Grab mode opens them again (back to 0.18).
- [x] Smooth, not a snap — measured mid-transition at 0.38.
- [x] A clenched fist obeys STO-CHARACTER-058: no segment is inside
      the palm at any curl, including 1.0.
- [x] Proven by a headless test (10 checks, shared with 059).

## Depends on

- **STO-CHARACTER-057** — the fingers.
- **STO-CHARACTER-058** — so a clenched fist is a real fist shape.
