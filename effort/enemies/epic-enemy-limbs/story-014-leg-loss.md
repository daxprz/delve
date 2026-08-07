---
xid: STO-ENEMIES-014
parent: ./epic.md
kind: story
effort: enemies
size: S
status: draft
date: 2026-08-07
depends-on: [STO-ENEMIES-012]
bd-id: delve-7vh
---

# One leg slows them, both legs kill them

## Summary

Take one of an enemy's legs and it can only limp after you — much
slower, much easier to get away from. Take **both** and it dies.

This makes going for the legs a real tactic: you cannot kill something
with one leg hit, but you can make it stop being a threat and deal
with it later. It suits the Runner especially, whose tail sweeps low
and fast.

## Definition of Done

- [ ] An enemy missing one leg moves clearly slower than a whole one.
- [ ] "Clearly slower" is a measured number, not a guess — the test
      compares the two speeds.
- [ ] An enemy that loses **both** legs dies.
- [ ] Losing a leg does not break its walking animation or leave it
      sliding along the floor.
- [ ] It leaves a body behind (STO-ENEMIES-016).
- [ ] Proven by a headless test.

## Out of scope

- Crawling on the ground with no legs — losing both is death, not a
  new way of moving.

## Depends on

**STO-ENEMIES-012** — legs cannot come off until limbs can come off.
