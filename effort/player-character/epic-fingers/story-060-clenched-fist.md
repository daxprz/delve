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

- [ ] Punch mode curls every finger to fully closed.
- [ ] The thumb closes over the fingers, as a real fist does.
- [ ] Grab mode opens them again.
- [ ] Switching modes is smooth, not an instant snap.
- [ ] A clenched fist obeys the limits from STO-CHARACTER-058 — no
      fingers poking through the palm.
- [ ] Proven by a headless test that toggles the mode and checks the
      curl.

## Depends on

- **STO-CHARACTER-057** — the fingers.
- **STO-CHARACTER-058** — so a clenched fist is a real fist shape.
