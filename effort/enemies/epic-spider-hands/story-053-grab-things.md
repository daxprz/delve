---
xid: STO-ENEMIES-053
parent: ./epic.md
kind: story
effort: enemies
size: L
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-noo0
---

# The arms take hold of things

## Summary

> "let them grab things" — operator, 2026-08-14

The arms **take hold of an object** and keep hold of it. Not a player —
that is STO-ENEMIES-034 and already written. This is the world: crates,
ledges, whatever is there.

## Why this is the hinge of the epic

Grabbing a thing is what makes swinging possible, and swinging is what
the operator actually asked for. A hold is also the first thing this
creature has ever done that is **not** an attack — and a monster that
can pick something up is a different kind of frightening from one that
can only hit you.

## What a hold has to be

- **Real.** The held thing follows the pincer, or the pincer follows
  the held thing if it cannot be moved. A ledge does not move; a crate
  does.
- **Releasable.** It can let go deliberately, which is the whole basis
  of 054.
- **One thing per arm.** Two arms, two holds, and that is the maximum —
  which is exactly what makes swinging a decision rather than a
  cheat.

## Definition of Done

- [ ] An arm can take hold of an object within reach.
- [ ] The hold is real: a light object follows the pincer, and a fixed
      one holds the pincer instead.
- [ ] It can let go on purpose.
- [ ] Each arm holds at most one thing, so two is the limit.
- [ ] Letting go leaves the object behaving normally, not stuck or
      flung.
- [ ] Proven by a headless test that grabs, moves, and releases, and
      measures the object at each step.

## Out of scope

- Throwing what it holds.
- Grabbing players — that is STO-ENEMIES-034.
- Breaking what it holds.
