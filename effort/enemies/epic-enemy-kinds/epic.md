---
xid: EPI-ENEMIES-ENEMY-KINDS
parent: ../design.md
kind: epic
effort: enemies
status: open
date: 2026-08-14
bd-id: delve-0ic
---

# More than one kind of enemy

## Summary

delve has exactly **one** creature. Every enemy is the same thing: 60
health, walks at you, swings for 12. Its body varies — size, mass and
balance all come from a seed — but it always *behaves* the same and
always looks like the same humanoid.

This epic gives enemies **kinds**, the way players already have
characters. `CharacterDB` lists Grabber, Runner, Flyer and Sniper with
their own stats; enemies have nothing like it.

## Definition of Done

- [ ] There is a list of enemy kinds, each with its own stats and body.
- [ ] Adding a kind does not mean editing the enemy's brain.
- [ ] Every kind still ragdolls, loses limbs and leaves a body.
- [ ] Kinds are the same on every machine in multiplayer.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 017 | enemy-registry | S | the list — **everything else is an entry in it** |
| 018 | crawler | M | four legs, a block for a body |

## Out of scope

- A boss. It will be a kind too, once kinds exist.
