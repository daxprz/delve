---
xid: STO-ENEMIES-058
parent: ./epic.md
kind: story
effort: enemies
size: M
status: draft
date: 2026-08-15
depends-on: []
bd-id: delve-pdui
---

# The pincer arms are physics too

## Summary

> "make the spiders arms colidable like the legs"

The legs became real physics bones in STO-ENEMIES-055. The **pincer
arms did not** — they are still animated ghosts, so nothing can touch
them and they can pass through anything.

This is the smallest story in the epic and the one everything else
waits on: an arm has to be a real object before it can be hit, held or
pulled off.

## It should be nearly free

`spider_solid.gd` already builds a bone per limb segment, drives it
toward the pose the gait asks for, excludes same-limb pairs from
colliding, and reports knocks. It reads its segments from
`quadruped_body.limb_segments()`, which today lists **legs only**.

If the arms are added to that list with the same shape of data, they
should become physics for free. If they do not, that is worth knowing:
it means the bone code is quietly leg-shaped and the story is bigger
than it looks.

## Definition of Done

- [ ] The pincer arms are physics bones, like the leg segments.
- [ ] They collide with the world and with players.
- [ ] They do NOT collide with the arm they are part of — adjacent
      segments share a joint and would fight for ever
      (STO-ENEMIES-055 learned this the hard way, at 335 m).
- [ ] The arms still reach, grab and weave exactly as they do now.
- [ ] Measured: an arm cannot end up inside a wall as deeply as it can
      today. Compared against the current build, not judged by eye.
- [ ] The cost of four more bones per spider is measured.

## Out of scope

- Hitting them, which is 059.
- Making the LEGS better. They are done.
