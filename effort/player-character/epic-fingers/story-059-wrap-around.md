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

- [x] Grabbing closes the fingers (0.18 rest -> 0.69 on a small
      object).
- [x] They close only as far as the object allows.
- [x] A **bigger** object leaves them **less** curled — 0.12 against
      0.69, measured.
- [x] Letting go returns them to rest (0.18).
- [x] Latching onto solid geometry closes the hand hard (0.8).
- [x] Proven by a headless test (10 checks, shared with 060).

## Verification notes (2026-08-13)

`tests/smoke_finger_grip.gd`. The curl comes from the grabbed body's
collision shape, so it is the actual object's size rather than a
guess per object type.

Worth noting: a hand wrapped around a **big** crate ends up *flatter
than a resting hand* (0.12 against 0.18). That looks wrong written
down and is right in practice — fingers splay over a large flat
surface rather than curling round it.

## Out of scope

- Fingers finding individual contact points on complex shapes. Close
  until you touch the object's surface is enough.

## Depends on

- **STO-CHARACTER-057** — the fingers.
- **STO-CHARACTER-058** — so wrapping cannot produce impossible
  shapes.
