---
xid: STO-ENEMIES-057
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
date: 2026-08-15
depends-on: []
bd-id: delve-1imk
---

# The giant spider really stumbles

## Summary

> "make it so the giant spider stumbles" — operator, 2026-08-15

It could barely be tripped, and when it was you could hardly tell. Both
halves are fixed: it is **easier to knock off its stride**, and the
stumble is a **real lurch you can see across the room**.

## What was actually wrong

Two numbers, found by looking rather than guessing:

| | before |
|---|---|
| stability | **3.2** — more than three times a Walker's |
| a Walker stumbles at | dv 3.0 |
| the giant spider stumbled at | dv **9.6** |
| it was knocked down at | dv **24.0** |
| and the stumble was | a **12.6°** body dip |

So the operator had almost certainly never seen it stumble. Its own
toughness had put the reaction out of reach of anything that happens in
play, and the reaction it was missing out on was nearly invisible
anyway.

That combination is the worst kind of bug: a feature that exists, is
correct, is tested, and never once appears.

## What "really stumbles" means

- **Reachable.** A solid hit should throw a giant spider off its
  stride. It should still take much more than a Walker needs — it is
  supposed to be heavy — but not more than the game can deliver.
- **Big.** A creature this size losing its footing should be
  unmistakable: a deep lurch, legs going loose under it, and a moment
  before it gathers itself.
- **Still hard to knock DOWN.** Stumbling and falling over are
  different tiers and must stay different. Making it trip easily must
  not make it topple easily, or the towering monster becomes a
  pushover.

## Definition of Done

- [x] A hit the game can deliver trips it: an impulse of 32 leaned it
      **35.5°**.
- [x] The lurch is **big** — 35.5° against the **12.6°** it used to
      manage, on a creature three metres tall.
- [x] It is still much harder to trip than a Walker: a tap that rocked
      a Walker **13.0°** left the giant at **0.0°**.
- [x] Knocking it DOWN is no easier. Untouched at dv 24, and measured:
      an impulse of 44 (dv 20) stumbles it and does **not** floor it.
- [x] Its legs go loose during it.
- [x] It gathers itself back up — settled to 0.00°.
- [x] Proven by `tests/smoke_spider_stumble.gd`, 3/3 stable.

## Built (2026-08-15)

**Tripping and toppling are separate numbers now.** Stability stays at
3.2, so felling it is exactly as hard as it was; a new trip resistance
of 1.35 governs only the stumble. Everything else in delve falls back
to plain stability, so no other creature changed.

The bug underneath was a good one to find: **a feature that existed,
was correct, was tested, and never once appeared.** Its own toughness
had put its own reaction out of reach of anything the game could
deliver.

**Both of my test failures were arithmetic**, and both blamed the
feature for it. dv is impulse ÷ mass, and I twice guessed the mass —
first 3.1 when it is 2.17, then multiplying my impulses by 3. The first
delivered dv 25 against a knockdown threshold of 24, so the test
reported "the spider does not stumble" when what had actually happened
was that it had been **floored**.

## Out of scope

- Changing what knocks it down. Only the stumble tier moves.
- Other creatures' stumbles.
