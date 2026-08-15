---
xid: STO-CHARACTER-076
parent: ./epic.md
kind: story
effort: player-character
size: L
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-nrrc
---

# Press E and he flattens onto the plane he is facing

## Summary

> "he should press e then turn 2d and every thing infron of him is the
> 2d plane hes on"

Press **E** and the Mage steps sideways into the second dimension.
Press it again and he comes back.

## Which plane?

**Everything in front of him.** He chooses the plane by where he is
facing at the moment he presses the key — so aiming himself before he
flattens IS the skill. Face down a corridor and the corridor is your
world; face a wall and you have chosen a very small world indeed.

The plane is fixed once he is in it. It does not follow him round as
he turns, because a plane that re-chose itself every frame would not be
a place — it would just be a strange way of walking.

## ⚠️ The E key is already taken

**E is the rescue key** (STO-ENEMIES-035, built earlier the same day).
Both cannot own it. Settle this before building.

## Definition of Done

- [ ] Pressing E turns the Mage 2D.
- [ ] Pressing it again turns him back.
- [ ] The plane is chosen from where he is FACING when he presses it.
- [ ] The plane stays put while he is in it — turning does not move it.
- [ ] He comes back where he actually is, not where he started.
- [ ] Coming back inside solid rock is handled and does not trap him.
- [ ] Only the Mage can do it.
- [ ] The E-key conflict with the rescue is resolved, deliberately, and
      written down.
- [ ] Proven by a headless test.

## Out of scope

- What it LOOKS like, inside or out — 078 and 079.
- Slipping through gaps — 077.
- Enemies — 080.
