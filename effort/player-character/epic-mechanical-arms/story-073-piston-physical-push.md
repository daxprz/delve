---
xid: STO-CHARACTER-073
parent: ./epic.md
kind: story
effort: character
size: L
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-avxl
---

# The piston is always out, heavy to turn, and pushes with its own momentum

## Summary

Seven changes that turn the piston from a pose that fires into a
**heavy machine you carry**.

| # | change |
|---|---|
| 1 | in piston mode you **cannot grab** at all |
| 2 | a **different model** — it should not look like the fists |
| 3 | the arms are **always out** in piston mode, not only while firing |
| 4 | `LMB` + `RMB` shoots it out and **pushes** what it meets |
| 5 | it has **collision** — a solid thing in the world |
| 6 | it **turns slowly**, lagging behind where you look |
| 7 | the push comes from the piston's **own momentum**, not from nothing |

## Point 7 refines an earlier decision, deliberately

STO-CHARACTER-071 said the piston must NOT use momentum. That was
about **damage** — the operator wanted a predictable hit, unlike the
Runner's claws where speed is everything.

This is about the **push**. What launches an enemy should be the
piston actually shoving into them: a slow stroke nudges, a fast one
throws them. So the force comes from how fast the head is travelling
when it connects, rather than a fixed number applied the instant a
check passes.

Not a contradiction — the charge sets the speed, and the speed does
the pushing. Damage and shove are two different questions.

## Point 6 is what will make it feel heavy

Today the joined hands follow the camera instantly, so the piston
whips around as fast as you can turn. It should **lag**: you swing
your view and the machine catches up. That single change is most of
what separates a heavy machine from a pose.

## Definition of Done

- [ ] Grabbing is impossible in piston mode — `LMB`/`RMB` never latch.
- [ ] The piston has its own model, clearly not two fists.
- [ ] The arms hold it out **whenever the mode is on**, not only
      during a stroke.
- [ ] `LMB` + `RMB` fires it; what it meets is pushed away.
- [ ] It is collidable while held out, not only while striking.
- [ ] Turning swings it **slowly** — measured as lag behind the
      camera, not eyeballed.
- [ ] The push scales with head speed: a slow stroke barely nudges, a
      full one throws.
- [ ] Enemies still ragdoll; players still keep control.
- [ ] Proven by a headless test measuring the turn lag and the push
      against stroke speed.

## Out of scope

- The piston blocking or parrying.
