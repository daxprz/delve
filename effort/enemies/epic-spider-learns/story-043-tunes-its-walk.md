---
xid: STO-ENEMIES-043
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-0kye
---

# It tunes its own walk

## Summary

The spider **starts already knowing how to walk** and gets better at it
while you play.

This is the operator's idea, and it is what makes the whole epic
buildable:

> "give it basic knowlge of walking so it seems like its already existed
> before the player was there so it still needs to learn without having
> to go through hundreds of genorations"

So it never learns from nothing. It begins with the gait it has always
had, then **nudges it and keeps what worked** — a little longer in the
stride, a little more or less lift — judged on how fast it actually got
where it was going.

## How it works, honestly

Hill-climbing, not a neural network. Each time it has walked for a
while it tries a small change to one gait number, measures the speed it
actually achieved, and keeps the change only if it did better. Worse,
and it goes back.

That is enough to look alive. A creature that walks slightly differently
after ten minutes than it did at the start reads as *practising*, which
is exactly the impression asked for.

## Definition of Done

- [x] It starts with a gait that already works — stride 1.000, the one
      it has always had, asserted directly.
- [x] It changes its stride, measures how far it actually got, and
      keeps only improvements.
- [x] After a while walking its stride is measurably different:
      **1.000 → 1.350** over 49 attempts.
- [x] It never tunes itself into being unable to walk — clamped to
      0.75–1.35, and the test asserts the final value is inside that.
- [x] Proven by `tests/smoke_spider_mind.gd`, against a fresh mind.

## Out of scope

- Learning to walk from scratch. Explicitly rejected; see the summary.
- Tuning anything except the walk.
