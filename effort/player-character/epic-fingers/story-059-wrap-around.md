---
xid: STO-CHARACTER-059
parent: ./epic.md
kind: story
effort: character
size: M
status: draft
date: 2026-08-13
depends-on: [STO-CHARACTER-057, STO-CHARACTER-058]
bd-id: delve-e9x
---

# Fingers wrap around what you grab

## Summary

Grab something and the fingers **close around it** — curling until
they meet the object rather than curling a fixed amount. A thin bar
gets a tight grip; a big crate gets a wide one.

That is the whole payoff of having fingers: you can see the hand
holding the thing.

## Definition of Done

- [ ] Grabbing closes the fingers.
- [ ] They stop when they reach the object instead of curling
      straight through it.
- [ ] A **bigger** object leaves the fingers **less** curled than a
      small one — measured, not eyeballed.
- [ ] Letting go opens them again.
- [ ] It works on both a crate and a grabbed enemy.
- [ ] Proven by a headless test comparing the curl on objects of
      different sizes.

## Out of scope

- Fingers finding individual contact points on complex shapes. Close
  until you touch the object's surface is enough.

## Depends on

- **STO-CHARACTER-057** — the fingers.
- **STO-CHARACTER-058** — so wrapping cannot produce impossible
  shapes.
