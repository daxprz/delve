---
xid: EPI-ENEMIES-SPIDER-HANDS
parent: ../design.md
kind: epic
effort: enemies
status: open
date: 2026-08-14
bd-id: delve-7rr0
---

# The spider's arms feel, grab and swing

## Summary

> "make the spiders arms longer and make them feel around with there
> arms being able to learn how to swing with letting go and grabing and
> let them grab things" — operator, 2026-08-14

The pincer arms stop being weapons that happen to wave about, and
become **hands**. They feel their way around, they take hold of things,
and — the big one — the spider **learns to swing along by them**,
letting go with one and catching with the other.

## Why this is a bigger deal than it sounds

Every creature in delve moves by walking. This is the first one that
could move by **holding on**.

It also joins two things that were separate: the arms
(EPI-ENEMIES-SPIDER-TAKES-YOU) and the mind
(EPI-ENEMIES-SPIDER-LEARNS). Swinging is not a canned animation — the
operator asked for it to be **learned**, which means it belongs to the
same hill-climbing that already tunes the walk (STO-ENEMIES-043).

A spider that can haul itself along the ceiling, badly at first and
better later, is a different creature from one that walks at you.

## Longer arms ✅ (2026-08-14)

Done first, because nothing else here works without it. Arm length went
from **0.85 × body height to 1.35**, taking the reach on a 3.12 m
spider from **3.82 m to 6.06 m**.

It is not only a look. Feeling around needs arms that reach past where
the feet already are, and swinging needs arms long enough to hold one
grip while the other searches for the next.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| — | longer arms | S | ✅ Done. 3.82 m → 6.06 m reach. |
| 052 | feel-around | M | The arms sweep and probe what is near. |
| 053 | grab-things | L | They take hold of objects, not just people. |
| 054 | learn-to-swing | L | Let go, catch, move along by the arms — and **learn** it. |

Built in that order: it has to feel before it can choose what to grab,
and it has to grab before letting go means anything.

## Definition of Done

- [x] The arms are long enough to reach well past the body.
- [ ] They feel around, and what they touch is something the creature
      knows about.
- [ ] They can take hold of a thing in the world.
- [ ] It can hold with one and let go with the other.
- [ ] It gets **better at swinging** the more it does it, from a
      starting point that already half-works — the same rule as the
      walk (STO-ENEMIES-043).
- [ ] Every one proven by a headless test, each measured against a
      spider that has NOT learned.

## Out of scope

- Other creatures grabbing or swinging. These are the spider's arms.
- Swinging on nothing. It needs something to hold.
- Web. It is a spider with arms, not a spider with silk.
