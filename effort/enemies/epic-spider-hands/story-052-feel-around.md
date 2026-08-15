---
xid: STO-ENEMIES-052
parent: ./epic.md
kind: story
effort: enemies
size: M
status: draft
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

## Definition of Done

- [ ] Idle, the arms sweep the space around the creature.
- [ ] What a tip touches is recorded — what and where.
- [ ] It only senses things within actual arm's reach.
- [ ] It finds things the radar does not: walls, ledges, objects.
- [ ] Reaching for a player still takes priority over feeling around.
- [ ] Proven by a headless test that puts something within reach and
      something outside it, and checks it finds ONLY the near one — a
      test with one object would pass for a sense that returns
      everything in the level.

## Out of scope

- Acting on what it feels. Knowing is this story; using it is 053.
- Feeling with its legs.
