---
xid: STO-ENEMIES-019
parent: ./epic.md
kind: story
effort: enemies
size: S
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-bad
---

# The crawler looks like a spider

## Summary

The crawler should read as a **spider**: one block for a body — no
head — carried on **big** legs that splay out to the sides.

It currently has a small body plus a separate blunt head, on short
legs that hang straight down underneath it. That reads as a little
table, not a spider.

Three changes, all generated in code as before:

- **One block only.** Drop the head.
- **Bigger legs.** Long and thick enough that the legs, not the body,
  are what you see.
- **Splayed.** A spider's legs go OUT and UP from the body, then bend
  down to the ground — the knee sits **above** the body. Legs hanging
  straight down are what makes it look like furniture.

## Definition of Done

- [x] The body is a single block — the head is gone.
- [x] Legs nearly twice as long (0.46 -> 0.86) and thicker (0.09 -> 0.13).
- [x] All **4 of 4** feet land outside the body's width (half-width
      0.23), measured.
- [x] All **4 of 4** knees rise above the body.
- [x] The block hangs between the legs at 52% of leg length.
- [x] Still seeded — three built came out 0.40, 0.37 and 0.45 wide.
- [x] Still walks in diagonal pairs and still ragdolls — every
      STO-ENEMIES-018 check still passes.

## Verification notes (2026-08-14)

Two geometry faults, both invisible reading the code and both obvious
once the test printed numbers:

- **The splay was less than 90 degrees.** A knee can only rise above
  the body if the first segment tilts PAST vertical. At 1.05 rad (60)
  the knee direction was y **-0.50** — below the body, which is
  exactly why it read as a small table. At 2.05 rad (117) it is
  y **+0.46**.
- **The splay sign was flipped**, so legs angled INWARD and crossed
  under the body. That is why only 2 of 4 feet were outside its width.

The knee fold had to move into the **same plane** as the splay too:
folding about the local X axis while the leg was rotated about Z swung
the shin sideways instead of down to the floor.

## Out of scope

- Eight legs. Four for now.
- Webs or climbing.
