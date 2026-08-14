---
xid: STO-ENEMIES-028
parent: ./epic.md
kind: story
effort: enemies
size: S
status: draft
date: 2026-08-14
depends-on: [STO-ENEMIES-023]
bd-id: delve-z25v
---

# Seen from above, the spider is an X

## Summary

Looking straight down at the spider, its four legs should form an **X**
with the body at the crossing point — one leg reaching out into each
corner.

Today they splay out to the **sides** only. From overhead that reads as
`=` — two rows down its flanks — rather than `X`.

## Definition of Done

- [ ] Each foot lands out along its own diagonal: both its x and its z
      well away from zero, and roughly equal.
- [ ] One foot in each of the four quadrants.
- [ ] The body sits at the crossing point.
- [ ] Everything else still holds: it towers, feet reach the ground,
      diagonal-pair walking, ragdolling.

## Attempted and reverted (2026-08-14)

Rotating each leg root by +/-45 degrees about Y, expecting that to
send each corner's leg along its own diagonal. **Both signs were
tried and neither worked:**

| yaw | where the feet landed |
|---|---|
| `-side * fore * 45` | (-0.3,-2.4) (2.2,-0.4) (-0.4,2.2) (2.3,0.3) |
| `+side * fore * 45` | (-2.3,-0.1) (0.4,1.8) (-2.2,-0.1) (0.3,-2.0) |

Both are nearly **axis-aligned**, and the second put two legs in the
same quadrant. So the premise is wrong: the legs are not splaying
along their local X the way the yaw assumed, and a 45-degree turn
about Y does not compose with the segment rotations the way I
expected.

Reverted rather than left lopsided. The next attempt should **measure
first** — print the actual splay direction of one leg in body space
before deciding what to rotate — rather than reasoning about the
composition of the rotations, which is what failed here twice.
