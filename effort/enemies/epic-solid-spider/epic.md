---
xid: EPI-ENEMIES-SOLID-SPIDER
parent: ../design.md
kind: epic
effort: enemies
status: open
date: 2026-08-14
bd-id: delve-sld1
---

# The spider is solid: limbs that collide

## Summary

The spider's legs and pincers stop being ghosts. They **cannot pass
through walls, crates or the floor**, and they **cannot pass through
each other**.

Right now they sweep straight through anything in the way, which is
the single thing most likely to break the illusion of a heavy creature
— all the floppiness in the world does not help if a leg goes through
a wall on the way.

## Everything, including itself (operator, 2026-08-14)

> "it should colide with everything even its other legs so it has to
> learn how to work aganst everything and even itself"

Self-collision is not a polish item on this epic, it is the **point**.
The spider is meant to have to work against a body that genuinely gets
in its own way — legs that can foul each other are a constraint it has
to solve, and solving constraints is what the learning epic is for.

Which settles the order: **this epic comes first.** Learning to move
inside a body that can pass through itself is learning to solve a
problem that does not exist.

## Why this is separate from the learning

The operator asked for collision and intelligence in the same breath,
but they are different jobs. Collision is **physics**, and it is small
and testable. Learning is **behaviour**, and it is large.

Doing collision first also makes the learning honest: a spider that
learns to move while its legs pass through the world is learning to
move in a world that is not really there.

## There is already a working answer in delve

The Grabber's arm chain does exactly this (`_collide_chain` in
`mechanical_arms.gd`): each link ray-checks from its joint to its far
point and clamps to the first surface it meets. Eight legs and two arms
is the same idea, more of it.

Worth reusing rather than reinventing — it is proven, and it already
handles the awkward part, which is killing the velocity into a surface
so a limb rests against it instead of vibrating.

## Stories

| # | Slug | Notes |
|---|------|-------|
| 041 | limbs-hit-world | Legs and pincers stop at walls, crates, the floor. |
| 042 | limbs-hit-self | Limbs cannot fold through one another. |

## Definition of Done

- [ ] A leg swung at a wall stops at the wall.
- [ ] It rests against a surface rather than juddering on it.
- [ ] Limbs do not intersect each other.
- [ ] The spider still walks, clambers and ragdolls.
- [ ] It does not cost so much that the game slows down — measured,
      with the number written down.
- [ ] Proven by a headless test.

## Out of scope

- Limbs pushing things. They stop at the world; they do not shove it.
- Collision while ragdolled — real physics already owns that.
