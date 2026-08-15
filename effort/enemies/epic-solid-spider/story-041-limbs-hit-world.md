---
xid: STO-ENEMIES-041
parent: ./epic.md
kind: story
effort: enemies
size: L
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-slw1
---

# Limbs cannot pass through the world

## Summary

The spider's legs and pincers stop at walls, crates and the floor
instead of sweeping through them.

## Attempt 1 — REFUSING THE POSE. Does not work. (2026-08-14)

The first approach was to treat each frame's limb pose as a
**proposal**: ray-check every segment, and any segment that would end
up inside the world keeps its previous joint angle instead, with the
spring's velocity killed so it rests rather than hammers.

It refused **10 segments per frame** against a wall. It changed
nothing:

| | collision ON | collision OFF |
|---|---|---|
| deepest a limb reached into the slab | 0.569 m | **0.568 m** |
| worst self-overlap | 0.1898 m | **0.1896 m** |

### Why it cannot work

Refusing a pose freezes a joint **angle**. Where a limb actually *is*
depends on the angle **and on where the body is** — and the body keeps
walking forward, carrying the frozen limb in anyway.

Worse, the stored "safe" angle goes stale. It was clean when the body
was a metre further back; once the body advances, that same angle is
buried in the wall, so the fallback is no better than the pose it
replaced.

**A constraint that only refuses change cannot fix a violation caused
by something else moving.**

### The test nearly hid it

The only check that told the two builds apart was "10 segments
refused" — which measures that the code **ran**, not that it
**achieved** anything. The two measurements that matter were identical
to within a millimetre, and a self-overlap threshold set at the limb
thickness passed in both builds.

Same shape as the pass-counting mistake recorded earlier in this
project: *a function working is not the same as the thing working.*

The code was reverted rather than left in. It cost a raycast per
segment plus an O(n²) sweep every frame and bought nothing, and dead
weight that looks like a feature is worse than no feature.

## What to try next

The limb has to be **moved out**, not merely stopped from moving in —
and recomputed from where the body is *now*, never from a remembered
angle.

Most promising: on a blocked segment, sample clearance at the current
angle plus and minus a small step on each axis, move whichever way
increases clearance, and repeat two or three times. That is a cheap
numerical gradient, it needs no stored history so it cannot go stale,
and it actively pulls the limb out however the body moves.

Second option, and possibly better for how this creature should feel:
**let the legs stop the body.** If a leg cannot find a clear pose, the
spider does not advance. That makes the world genuinely push back and
lines up with the operator's intent — "so it has to learn how to work
aganst everything" — because a body that cannot walk into walls is a
constraint the learning epic has to solve.

## Definition of Done

- [ ] A leg meeting a wall stops at it, measured as **less** limb
      inside the wall than with collision disabled. The comparison
      against a disabled build is required, not optional.
- [ ] It rests against a surface rather than juddering on it.
- [ ] The spider still walks, clambers and ragdolls.
- [ ] Cost measured and written down.
- [ ] Proven by a headless test whose checks **fail** when collision is
      switched off. A check that only proves the code ran does not
      count.

## Out of scope

- Limbs pushing objects around. They stop at the world.
- Collision while ragdolled — real physics owns that already.
