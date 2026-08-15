---
xid: STO-CHARACTER-078
parent: ./epic.md
kind: story
effort: player-character
size: L
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-he52
---

# His own view becomes a platformer

## Summary

> "for him it looks like a platformor"

Flat, **his own view becomes a flat game**. The camera swings side-on
to his plane and he moves along it — left, right and up — the way an
old 2D platformer works.

This is the half of the trick only he sees, and it is the reason the
power feels like magic rather than like a squeeze through a gap. For a
few seconds he is not playing the same game as everybody else.

## Definition of Done

- [ ] Flat, the camera views his plane side-on.
- [ ] His movement is along the plane only.
- [ ] It reads as a platformer, not as a 3D game with a stuck camera.
- [ ] Coming back, the camera and controls return exactly as they were.
- [ ] Nobody else's view changes.
- [ ] Proven by a headless test measuring that his movement off the
      plane is zero while flat, and normal again afterwards.

## Out of scope

- Platformer-specific abilities. He moves; he does not gain a
  double-jump for being flat.
- Changing anyone else's camera.
