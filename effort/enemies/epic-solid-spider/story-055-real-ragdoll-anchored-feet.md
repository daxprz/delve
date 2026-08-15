---
xid: STO-ENEMIES-055
parent: ./epic.md
kind: story
effort: enemies
size: L
status: draft
date: 2026-08-15
depends-on: []
bd-id: delve-ro1n
---

# The spider IS a ragdoll, held up by anchored feet

## Summary

> "i want every part of the spider be colidble with every thing so like
> a ragdoll make it have a stick point the bottem of the leg mucles so
> it doesnt just ragdoll and be on the floor and if you can make the
> legs colidable with eachother" — operator, 2026-08-15

Stop animating a ghost and then trying to stop it entering things.
**Make the spider real physics all the time**, and solve the only
problem that creates — that a ragdoll falls over — by **sticking its
feet to the ground**.

## Why this is the right idea, and the two before it were not

Both previous attempts (STO-ENEMIES-041) tried to keep the animation
and *forbid* the bad poses. Both failed for the same reason, written
into that story:

> **A constraint that only refuses change cannot fix a violation caused
> by something else moving.**

Refusing a pose freezes a joint ANGLE, but where a limb *is* depends on
the angle **and where the body is** — and the body keeps walking
forward, carrying the frozen limb in anyway.

The operator's idea removes that problem instead of fighting it. A
rigid body **cannot** be inside a wall, because the physics engine will
not allow it. There is nothing to refuse and nothing to go stale. The
collision stops being something we enforce and becomes something that
is simply true.

## The stick point is the whole invention

A ragdoll spider would collapse in a heap — which is exactly what the
operator anticipated and answered in the same sentence: **a stick point
at the bottom of the leg muscles**.

Each foot gets pinned to the spot it is standing on. Pinned feet turn a
rag doll into a **puppet on struts**: the body is held up by the legs
because the legs are held down by the ground. Lifting a foot to take a
step is then simply releasing that pin, moving it, and pinning it
again — which is what walking *is*.

That also means the gait stops being an animation and becomes a
sequence of decisions about **which foot to unstick and where to put it
down** — and those are exactly the numbers STO-ENEMIES-043 already
knows how to practise. The learning epic gets something real to learn.

## What has to be true

| | |
|---|---|
| **Every part collides with everything** | body, all leg segments, both arms |
| **The legs collide with EACH OTHER** | the operator asked for this twice; it is the point, not polish |
| **It does not collapse** | the feet are stuck down |
| **It can still walk** | unstick a foot, move it, stick it again |
| **It can still be knocked over** | a hard enough hit tears the feet loose |

## The honest risks, written before starting

1. **It may be slow.** Ten colliding parts per spider, with
   self-collision, is far more physics than delve does today.
2. **It may look drunk.** Physics-driven creatures wobble in ways
   animation does not, and "wobbly" may not read as "heavy".
3. **It may fight the existing gait.** Everything in
   `quadruped_body.gd` assumes it can place a leg wherever it likes.
4. **Anchors can explode.** Pinning a moving rigid body to a point is
   the same "infinite acceleration" trap that made the dragged victim
   thrash (STO-ENEMIES-051). Springs, not teleports.

If it fails, it fails like the last two: **reverted, with the
measurements written down.** Three failed approaches recorded honestly
is worth more than one that half-works and is left in.

## Definition of Done

- [ ] Every part of the spider is a real physics body.
- [ ] No part can be inside a wall. Measured as **less** limb inside a
      slab than the animated version manages, not as "it looks better".
- [ ] Legs collide with each other, measured as a self-overlap smaller
      than the animated version's.
- [ ] It **stands up** — it does not end up lying on the floor.
- [ ] It still walks, and gets somewhere.
- [ ] It can still be knocked over, and still get up.
- [ ] The cost is measured and written down.
- [ ] Proven by a headless test that compares against the CURRENT
      spider on the same course. "It collides" is not the check;
      "it collides MORE than before, and still walks" is.

## Out of scope

- Other creatures becoming ragdolls. The Walker stays animated.
- Making the gait clever. This story only has to keep it walking;
  improving how it walks is STO-ENEMIES-043.
