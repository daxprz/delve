---
xid: STO-ENEMIES-018
parent: ./epic.md
kind: story
effort: enemies
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-wic
---

# A four-legged enemy with a block for a body

## Summary

A new enemy that is nothing like the humanoid: **four legs** carrying
a **small block** of a body. It scuttles rather than walks.

Generated in code like everything else in delve — the legs, their
placement and their stepping all built from numbers, with a seed so no
two crawlers are quite alike.

Four legs is the interesting part. The humanoid plants two feet and
swings its arms; a four-legged thing has to move its legs in a pattern
that keeps it up — diagonal pairs, so it always has support. That gait
is the story.

## Definition of Done

- [x] Exactly 4 legs and a small block body (0.50 x 0.34 x 0.68).
- [x] Legs, body and gait generated in code; seeded, so the two in
      the world came out 0.44x0.30x0.60 and 0.41x0.28x0.55.
- [x] Its legs step rather than slide, driven by its REAL velocity.
- [x] Diagonal pairs move together (front-left with back-right).
- [x] It chases the player like any enemy — same brain.
- [x] It ragdolls when hit hard, with its own 9-part skeleton.
- [x] Every peer sees the same crawler (kind rides the spawn).
- [x] Proven by `tests/smoke_crawler.gd` (17 checks).

## Verification notes (2026-08-14)

Two things only showed up by running it:

- **The gait is driven by real velocity**, not a number you set. The
  first test called `set_speed(4)` and measured nothing moving — the
  enemy overwrites it every tick with how fast it is *actually*
  travelling, and with no player in the scene it was standing still.
  That is the right design (a creature jogging on the spot looks
  broken) but it means the test has to give it somewhere to go.
- **It could not ragdoll at all.** `ragdoll.gd` built from a table of
  `Pelvis/Torso/Shoulder` paths that simply do not exist on a crawler,
  so it produced ZERO parts and fell back to a stagger. It now has its
  own 9-part skeleton — block plus two segments per leg — chosen by
  asking the body whether it has legs to count.

## The crash (2026-08-14)

Reported by the operator: *"it crashes whenever I try to ragdoll the
spider."*

A plain knockdown was fine — the reproduction had to go through the
tier BELOW a ragdoll. A **medium** hit puts an enemy in the stumble
tier, which calls `_body.call("buckle_leg", ...)`. That is a HUMANOID
move; a four-legged body does not have it:

```
SCRIPT ERROR: Invalid call. Nonexistent function 'buckle_leg'
              in base 'Node3D (QuadrupedBody)'
```

Headless that is only an error line. In a **debug build it halts the
game**, which is what the operator saw. So every spider that took a
glancing blow — not a flooring one — killed the session.

Guarded with `has_method` rather than a null check. A creature on four
legs has no single leg to buckle, so it lurches instead.

Found alongside it: a quadruped ragdoll has no `Torso` or `Pelvis`
part, so the Grabber's `_attach` handed back **null** and the arm held
nothing while believing it held an enemy. It now falls through to
whatever that creature's core part is called.

`smoke_crawler.gd` gained a phase that lands a medium hit
specifically, because every existing test used a full ragdolling blow
and sailed straight past the broken tier.

## Out of scope

- The crawler having its own attack — it chases and swings like the
  others for now.
- Climbing walls.

## Depends on

**STO-ENEMIES-017** — it is the second entry in the registry.
