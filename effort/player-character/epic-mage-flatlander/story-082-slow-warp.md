---
xid: STO-CHARACTER-082
parent: ./epic.md
kind: story
effort: player-character
size: M
status: done
date: 2026-08-14
depends-on: [STO-CHARACTER-076]
bd-id: delve-ujp2
---

# Reality warps slowly into flat, and it is mesmerising

## Summary

> "the warping would slowly warp and very mezmorizing and it slowly
> trasitons" — operator, 2026-08-14

**This is what "warping reality" means.** It is not a separate power —
it is *how he goes 2D*.

Reality does not snap flat. It **warps**: the world bends and folds
toward the plane over a slow, deliberate, **mesmerising** transition,
and slides back the same way when he returns.

## Why this answer is better than a separate power

The first reading of "warp reality" was a whole second ability — moving
walls about, flipping gravity, tearing portals. The operator's actual
answer is smaller and much stronger: **the warp IS the transition**.

That means the Mage has **one** power, not two, and all the strangeness
is concentrated in the moment it happens. One power you cannot look away
from beats two you half-notice.

It also gives the ability a **cost**, which it did not have before: the
transition is slow, so flattening is a commitment. You cannot flick in
and out of the second dimension to dodge — you have to decide, and then
live through the seconds it takes.

## What "slow and mesmerising" has to mean in practice

- **Slow enough to watch.** Somewhere around a second or two, not a
  frame. If a player never says "look at this", it is too fast.
- **Continuous, not a flash.** It bends through every stage between
  round and flat. A fade-to-black-and-appear-flat is exactly the wrong
  thing and would be much easier to build — do not.
- **Both ways.** Coming back warps too, in reverse.
- **Interruptible or not — decide and write it down.** If a warping
  Mage can be hit halfway, say what happens.

## Definition of Done

- [x] Pressing F begins a visible warp, not an instant change.
- [x] It takes **1.2 s** — the same length as the camera glide, so the
      two are one movement rather than two effects finishing at
      different moments.
- [x] It passes through every in-between state. Sampled six times
      across the warp: **0.14, 0.30, 0.47, 0.64, 0.81, 0.97** — each
      further on than the last.
- [x] Caught halfway it is **0.47 warped**. A snap is never here.
- [x] Returning warps back at the same rate.
- [x] **He is not 2D until the warp finishes.** Measured: halfway
      through, his hitbox is still the round one, so being partly flat
      does not yet let him through anything. It goes thin on arrival
      and nowhere before.
- [x] **Hit mid-warp: the warp is CANCELLED.** Decided 2026-08-14.
      Being grabbed beats going flat — otherwise a Mage snatched
      halfway carried on warping while he was carried off and arrived
      on the spike as a sheet of paper, flat and held at once, in a
      state nothing else in the game knows how to reason about.
- [x] Proven by `tests/smoke_mage_warp_line.gd`, sampled throughout.

## Built (2026-08-14)

The cost the operator's answer bought: **you cannot flick in and out of
the second dimension to dodge.** 1.2 seconds is long enough that
flattening is a commitment you then have to live through.

## Out of scope

- Warping anything except himself. The world only *looks* like it is
  bending; nothing is actually moved.
- Other characters having a warp.
