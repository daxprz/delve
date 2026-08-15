---
xid: STO-CHARACTER-077
parent: ./epic.md
kind: story
effort: player-character
size: L
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-q1gb
---

# Flat, he fits through gaps that are otherwise impossible

## Summary

> "so hes able to slip through super small gaps or other things that
> would be imposble other wise"

This is **what the whole power is for**. Everything else in the epic is
how it looks; this is what it does.

Flat, the Mage has no depth, so a gap that is too narrow for a person
is not too narrow for him. Bars, cracks, the space under a door, a slot
in a wall — all of them become doors, but only for him, and only while
he is flat.

## Why this has to be genuinely true, not faked

It would be easy to make him *look* flat and quietly teleport him past
obstacles. Do not. The gap has to be a real gap and he has to really
fit, because the moment it is faked, the player will find the place
where the fake does not hold — and that place will be the most exciting
corner of the level, where they most wanted it to work.

## Definition of Done

- [x] Flat, the Mage passes through a **0.30 m** slot. He is 0.80 m
      across solid; his hitbox goes to **0.06 m**.
- [x] The SAME gap stops him when he is not flat. Identical wall,
      identical start, identical walk: **stopped at z=-5.33 solid,
      through to z=-10.20 flat.**
- [x] He still cannot pass through a solid, gapless wall — stopped at
      z=-5.30 while flat. Thin, not a ghost.
- [x] The hitbox belongs to the PLANE: it is re-aimed every tick, so
      turning while flat cannot make him solid inside a crack.
- [x] Proven by `tests/smoke_mage_gap.gd`, which walks the same journey
      twice and gets two different answers.

## Built (2026-08-14)

A capsule cannot be flattened, so going flat swaps the shape for a thin
box turned edge-on to the plane, and swaps the capsule back on the way
out — **before** the clearance check runs, so "is there room here?"
is always asked about the solid body.

The thin hitbox is **0.06 m**, deliberately fatter than he looks
(0.021 m). A hitbox thinner than the physics engine's own contact
margin starts falling through floors, and a Mage who drops out of the
world is a worse bug than one who is a centimetre too fat.

## Out of scope

- Carrying other players through with him.
- Taking objects through.
