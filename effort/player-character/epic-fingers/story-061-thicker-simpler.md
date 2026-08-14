---
xid: STO-CHARACTER-061
parent: ./epic.md
kind: story
effort: character
size: S
status: draft
date: 2026-08-13
depends-on: []
bd-id: delve-hjj
---

# Fingers are thicker and less detailed

## Summary

The fingers are too thin and too fiddly. Make them **chunkier** and
**simpler** — fewer little parts, more solid shape. They should read
as heavy mechanical fingers on a machine arm, not as delicate ones.

Each segment currently carries its own knuckle sphere, which at this
size is detail nobody sees and geometry everybody pays for: 5 fingers
x 3 segments x 2 hands = **30 spheres per player**.

## The catch worth naming

Thicker fingers make them more likely to **clip into each other** —
the exact thing STO-CHARACTER-058 fixed. Thickness and spacing are one
decision, not two: widening one means widening the other. The no-clip
test must still pass afterwards, and it is the thing that proves this
was done properly rather than just made fatter.

## Definition of Done

- [x] Fingers are visibly thicker (0.062 -> 0.090).
- [x] The per-segment knuckle spheres are gone (30 fewer meshes per player).
- [x] They still do not clip — the spread widened with them
      (0.32 -> 0.42) and 058's test still passes.
- [x] They still do not fold through the palm.
- [x] Every finger is still the same length.

## Out of scope

- Changing how they curl or grip.
