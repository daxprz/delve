---
xid: STO-ENEMIES-052
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-q3a0
---

# The arms feel around and it knows what they touched

## Summary

> "make them feel around with there arms" — operator, 2026-08-14

The arms **sweep the space around the creature** and it **knows what
they touched**. Not a look — a sense.

Today the arms only reach for a player it has already found by radar
(STO-ENEMIES-038). This gives it a second, much shorter-ranged sense
that works on **everything**: walls, ledges, crates, the ceiling. The
radar tells it where you are; the arms tell it what is within reach.

## Why it matters beyond looking creepy

Everything else in this epic needs it. You cannot decide what to grab
without knowing what is there, and you certainly cannot swing to the
next handhold without having felt for one.

It is also the first sense in delve that is about the **world** rather
than about the player, and that is what will let the creature use a
room rather than merely cross it.

## What "feeling around" means precisely

- The arms **sweep** when nothing else has their attention — a slow
  search, not the idle weave they do now.
- Whatever a tip passes through is **recorded**: what it was, and
  where.
- It is a short sense. Arm's length, no further — the whole point is
  that it is different from the radar.

## Creepier, specifically (operator, 2026-08-15)

> "make the arms when its not close to the player feel around and be
> able to grab and just make it look creepeir"

"Creepier" is not decoration here, it is the acceptance test, so it is
worth saying what makes searching creepy rather than busy:

- **Slow.** Fast is frantic; slow is deliberate, and deliberate is
  worse. A thing that is taking its time is a thing that expects to
  find you.
- **Out of step.** Two arms sweeping in sympathy read as one machine.
  Two arms on different rhythms read as two hands.
- **Reaching, then withdrawing.** An arm that extends into a space,
  hangs there, and draws back has *considered* that space.
- **It pauses.** The worst moment is the one where it stops.

## Definition of Done

- [x] With nobody near, the arms sweep. Measured: the tips cover
      **7.52 m** of space searching against **3.76 m** idling — twice
      as much, so it plainly LOOKS different rather than merely being
      flagged different.
- [x] The reach breathes **0.04 → 1.00**: they extend into a space and
      draw back out of it, rather than holding one pose.
- [x] The two arms sweep on different rhythms.
- [x] What a tip touches is recorded — what, where, and which arm.
- [x] It finds a wall the radar would not care about.
- [x] It senses only what is within reach: it felt the near obstacle
      and **not** the far one.
- [x] Reaching for a player takes priority — searching stops the moment
      anyone is close enough to reach for.
- [x] It forgets what it felt when it stops, so stale touches cannot be
      acted on later.
- [x] Proven by `tests/smoke_spider_feel.gd`.

## Built (2026-08-15)

**Three of the four bugs were in the test, not the feature**, and all
three made a working sense look broken:

1. The obstacle was put at the holder's origin — **three metres below
   the shoulders**. The tips swept an empty space and correctly
   reported nothing.
2. Guessing where the arms reach failed again, so the obstacle is now
   placed in the **middle of the volume the tips were just measured
   sweeping through**.
3. It was a 1.2 m box in a space the tips roam **six metres** across —
   a needle they only thread by luck. "It missed" is indistinguishable
   from "it cannot feel", so it is a wall-sized obstacle now.

The one real bug: **a ray that starts inside a body reports nothing**
in Godot by default. A tip creeping through a crate spends hundreds of
frames inside it and one frame crossing the surface, so the arms swept
straight through and felt absolutely nothing. `hit_from_inside` fixes
it.

## Out of scope

- Acting on what it feels. Knowing is this story; using it is 053.
- Feeling with its legs.
