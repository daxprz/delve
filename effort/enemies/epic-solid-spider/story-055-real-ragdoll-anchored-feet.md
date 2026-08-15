---
xid: STO-ENEMIES-055
parent: ./epic.md
kind: story
effort: enemies
size: L
status: in-progress
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

## Attempt 3, part done (2026-08-15)

Measured on the same course, against the spider as it was:

| | before | after |
|---|---|---|
| worst overlap between two legs | 0.1524 m | **0.1113 m** — 27% better |
| deepest limb inside a wall | 0.679 m | **0.677 m** — no change |
| it travelled | 5.51 m | 5.67 m |
| lowest the body rode | 2.54 m | 2.54 m |

**Legs colliding with each other WORKS** — the thing the operator asked
for twice. Bones were caught in the act, reporting contact with each
other and with the ground.

**Colliding with the world does NOT.** And the failure is understood
rather than mysterious, which is new: a foot was caught **0.44 m inside
a slab while reporting contact with that slab**. The collision is
detected; the drive simply wins the argument. Weakening the drive from
900 N/kg to 110 did not change it, so the remaining cause is something
else — most likely that a fast-swinging foot enters on one tick and the
solver cannot expel it before the drive re-commits.

### Four wrong turns, each of which looked like "collision does not work"

1. **The first measurement measured the PLAN.** The test read the
   animated chain — identical in both builds — and reported the physics
   version as a 1 mm improvement. The bones were never sampled at all.
2. **The bones exploded 335 m across the map.** Adjacent segments of
   one leg share a joint, so their capsules always overlap; the solver
   shoved them apart harder every frame. Same-leg pairs are excepted
   now; different legs still collide, which is the point.
3. **`global_transform` was still a teleport.** Rotation was being SET,
   which walks a rigid body through walls. It is spun with angular
   velocity now.
4. **Every collider was sideways.** The mesh was rotated to lie along
   the bone; the capsule was not. So the line being measured and the
   shape doing the colliding were at right angles.

Also `LOST_DISTANCE`, a safety net meant to catch lost bones, fired
constantly on bones that were merely **held back by a wall** — the
exact situation the feature exists to create — and teleported them
inside it.

### What is left

The world-collision half. The next thing to try is decoupling the
drive from the contact: stop commanding a bone that is currently
touching something, and let the solver own it until it is free.

## Definition of Done

- [x] Every leg segment is a real physics body — 12 bones.
- [ ] The pincer arms are not yet bones. Legs only.
- [ ] **No part can be inside a wall. NOT ACHIEVED** — 0.677 m vs
      0.679 m. The one headline goal, and it is not met.
- [x] **Legs collide with each other** — worst overlap 0.1524 m →
      0.1113 m on the same course.
- [x] It **stands up** — body rode 2.54 m, exactly as before.
- [x] It still walks — 5.67 m, no worse than the 5.51 m it managed
      before.
- [ ] It can still be knocked over, and still get up.
- [ ] The cost is measured and written down. **Not measured.** 12 extra
      rigid bodies per spider, with self-collision, and nobody has
      timed it.
- [ ] Proven by a headless test that compares against the CURRENT
      spider on the same course. "It collides" is not the check;
      "it collides MORE than before, and still walks" is.

## Out of scope

- Other creatures becoming ragdolls. The Walker stays animated.
- Making the gait clever. This story only has to keep it walking;
  improving how it walks is STO-ENEMIES-043.
