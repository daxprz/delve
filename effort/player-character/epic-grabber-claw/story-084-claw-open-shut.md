---
xid: STO-CHARACTER-084
parent: ./epic.md
kind: story
effort: character
size: M
status: draft
date: 2026-08-16
depends-on: []
bd-id: delve-o9qh
---

# Q works the left claw, E works the right

## Summary

> "the player can press e or q depoeding on which one it one of the
> closes or opens"

**Q works the left claw. E works the right.** Press to shut, press
again to open. Two hands, two keys, two independent claws — confirmed
by the operator on 2026-08-16.

That independence is the point: one claw can be holding something while
the other is still hunting. A single claw worked by two keys would be
simpler and much less useful.

## It should feel like the machine

A claw-machine claw is slow, deliberate and visibly mechanical. It does
not snap. The prongs travel, and you watch them travel — the same
instinct as the Mage's slow warp, and for the same reason: a moment you
can watch is a moment you can enjoy.

## Definition of Done

- [ ] Q toggles the left claw between open and shut.
- [ ] E toggles the right claw, independently.
- [ ] Each claw stays where it was put until pressed again.
- [ ] Opening and shutting is visible movement, not an instant state
      change — measured partway and found partway.
- [ ] It reads as a claw closing: the prongs come together.
- [ ] Proven by a headless test measuring how open each claw is, and
      that working one does NOT move the other.

## Out of scope

- Holding things, which is 085.
- Damage from the claw.
