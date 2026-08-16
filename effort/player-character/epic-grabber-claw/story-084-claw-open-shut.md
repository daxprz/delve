---
xid: STO-CHARACTER-084
parent: ./epic.md
kind: story
effort: character
size: M
status: done
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

- [x] Q toggles the LEFT claw: 0.05 → 0.95 → 0.05.
- [x] E toggles the RIGHT claw, independently.
- [x] Working one leaves the other alone — after Q the left is 0.95 and
      the right is still 0.05. Two claws, not one worked by two keys.
- [x] Each keeps its own state: shutting the right left the shut left
      shut.
- [x] It **travels**. Caught halfway, the left claw was **0.23** — not
      open and not shut, so it cannot be a snap.
- [x] The prongs are the five procedural fingers, curling together.
- [x] Proven by `tests/smoke_claw.gd`.

## Built (2026-08-16)

The claw is the FINGERS, not new geometry — `set_hand_curl` already
curls all five together, and the claw simply drives it slowly between
an open pose and a shut one. Keeping the fingers out of the Grabber's
cull (STO-CHARACTER-086) is what made this small.

Slow on purpose: 1.6 curl per second, so the travel is something you
watch. Same instinct as the Mage's warp, and the same reason.

## Out of scope

- Holding things, which is 085.
- Damage from the claw.
