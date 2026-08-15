---
xid: STO-ENEMIES-062
parent: ./epic.md
kind: story
effort: enemies
size: M
status: in-progress
date: 2026-08-15
depends-on: []
bd-id: delve-qo11
---

# Limbs steer around each other instead of shoving

## Summary

> "make it so its body parts path find around them so the arms dont bump
> into the legs or the legs push eachother" — operator, 2026-08-15

Limbs stop barging through each other and start **giving way**. An arm
coming down where a leg already is goes *around* it.

## This is not a reversal of "collide with itself"

Worth saying plainly, because at a glance it looks like one. The
operator asked earlier, twice:

> "it should colide with everything even its other legs so it has to
> learn how to work aganst everything and even itself"

Both are true and they are different things:

- **Colliding** is about what is POSSIBLE. A leg cannot be inside
  another leg. That stays.
- **Avoiding** is about what it CHOOSES. Given a leg already there, put
  this one somewhere else.

A creature that only collides shoves its own limbs about and jams. A
creature that avoids as well moves like it knows where its own legs
are. The constraint the operator wanted it to "work against" is still
there — this is the working-against.

## Why it is needed now

Adding the arms as physics bones (STO-ENEMIES-058) made this worse and
the numbers say so:

| | before the arms | after |
|---|---|---|
| worst overlap between two limbs | 0.1113 m | **0.2025 m** |

Arms and legs are separate collision groups, so they now push against
each other while the drive still commands both into the same space.
They fight, and the solver splits the difference. Neither wins and the
creature looks like it is wrestling itself.

## What "steers around" means here

Not literal path-finding — there is no route to plan and no graph to
search. Each limb is already being pulled toward where the gait wants
it; this adds a second, smaller pull **away from any other limb that is
too close**. Two forces, summed.

That is enough to produce the behaviour asked for and it costs almost
nothing, which matters when there are sixteen bones per spider. If a
gentle push apart is not enough, the next step is to move the gait
TARGET rather than the bone — but try the cheap thing first and measure
it.

## Attempt 1 — pushing the BONES apart. Failed. Reverted. (2026-08-15)

A second force on each bone, away from any other limb within 0.95 m,
at 1.4× the drive. Measured on the same course, twice:

| | worst overlap |
|---|---|
| avoidance ON | 0.1778 m |
| avoidance **OFF** | **0.1682 m** |

**It made the thing it was meant to fix worse.** Removed.

### Why it cannot work as a force on the bone

Same shape as the two failed collision attempts, and it should have
been predictable from them. The drive is still commanding both limbs
into the same place; pushing the bones apart does not change that
command, it just adds a second force for the drive to fight. The two
sum to a jitter, and a jittering bone finds its way further into things
than a steady one does.

**A force cannot fix a conflict between two INTENTIONS.** It can only
fight one of them.

### The comparison is what caught it

Tuned by feel it looked like progress the whole way — 0.2025 → 0.1911 →
0.1795 as the force went up — and every one of those was a real
measurement of a change that was making things worse. Only holding it
up against avoidance switched off showed it.

The repeatability check left behind says the run-to-run spread is
**0.0034 m**, so the 0.01 m "improvement" that the tuning appeared to
buy was three times the noise and still in the wrong direction.

### What to try next

Move the **gait target**, not the bone. Before the gait asks for a foot
at a spot, check whether another limb is already there, and ask for a
different spot. That changes the INTENTION, so there is nothing left to
fight — and it is the thing this story already predicted would be
needed if the cheap version was not enough.

## Definition of Done

- [ ] Limbs push away from other limbs that get too close.
- [ ] Worst overlap between two limbs is **measurably lower** than the
      0.2025 m it is today. Compared, not judged.
- [ ] A limb never avoids its own segments — they share joints and are
      meant to touch.
- [ ] The spider still walks and still stands.
- [ ] It does not start twitching: avoidance must settle, not
      oscillate.
- [ ] The cost is measured.
- [ ] Proven by a headless test comparing against avoidance switched
      OFF, so "the code ran" cannot pass for "the limbs moved apart".

## Out of scope

- Real path-finding for limbs.
- Avoiding the world. Walls are collision's job.
- Avoiding the player. Reaching for you is meant to bring an arm to
  where you are.
