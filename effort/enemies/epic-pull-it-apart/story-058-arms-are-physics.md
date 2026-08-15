---
xid: STO-ENEMIES-058
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
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

- [x] The pincer arms are physics bones — **12 bones became 16**.
- [x] They collide with the world and with players, on the same layer
      and by the same rules as the legs.
- [x] They do NOT collide with the arm they are part of. Each arm is
      its own group, well clear of the legs' pair numbers.
- [x] The arms still reach, grab, weave, search and feel — every one of
      `smoke_pincers`, `smoke_arms_reach`, `smoke_spider_feel` and
      `smoke_taken` still passes.
- [x] Measured, and better than expected: the deepest a limb reaches
      inside a wall fell from **0.677 m to 0.287 m**.
- [ ] The cost of four more bones is **not measured**. Still unticked.

## Built (2026-08-15) — it really was nearly free

The prediction in this story held: `spider_solid.gd` reads a list of
`{a, b, r, leg, name}` and knows nothing about what a leg or an arm is,
so the arms became physics by being **listed**. No new code path.

That is worth noticing as a design result, not just a lucky outcome.
The bone builder was written for legs and turned out not to be
leg-shaped, which is the whole reason this took one change instead of a
rewrite.

### An unexpected win, and an unexpected cost

| | legs only | with arms |
|---|---|---|
| deepest limb inside a wall | 0.677 m | **0.287 m** |
| worst overlap between two limbs | 0.1113 m | **0.2025 m** |

The wall figure more than halved — the arms now meet the wall first and
hold the creature off it, so the legs never get as deep. That is a real
improvement to STO-ENEMIES-055's unmet goal, arrived at sideways.

The overlap figure got **worse**, and honestly so: arms and legs are
different groups, so they now collide with each other, and the drive
still forces them into the same space. Recorded rather than hidden —
055 said self-overlap was the measure that worked, and this made it
worse.

## Out of scope

- Hitting them, which is 059.
- Making the LEGS better. They are done.
