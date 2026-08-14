---
xid: STO-CHARACTER-057
parent: ./epic.md
kind: story
effort: character
size: M
status: draft
date: 2026-08-13
depends-on: []
bd-id: delve-a86
---

# Five procedural fingers, two joints each

## Summary

Each of the Grabber's hands grows **five fingers**, and each finger
has **two joints** — so a finger is a chain of segments that can
curl, not a rigid stick.

Generated in code from the hand's size, the way every other part of
delve is built: no modelled mesh, no keyframes. A thumb sits apart
from the other four so the hand can actually close on something rather
than just flapping four fingers at it.

This story only *builds* them and lets them curl. Wrapping, clenching
and joint limits are the three stories that follow, and none of them
can start until fingers exist.

## Definition of Done

- [ ] Each hand has exactly 5 fingers.
- [ ] Each finger has 2 joints (so 3 segments including the tip).
- [ ] They are built in code and scale with `arm_scale`.
- [ ] One of them is a thumb, placed so it opposes the others.
- [ ] A finger can be curled by a single number (0 = straight,
      1 = fully closed) — the later stories all drive that number.
- [ ] Both hands have them, and they do not cost noticeable frame
      time.
- [ ] Proven by a headless test that counts fingers and joints and
      checks curling actually moves the segments.

## Out of scope

- What makes them curl — that is 058/059/060.
