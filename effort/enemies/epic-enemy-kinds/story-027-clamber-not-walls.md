---
xid: STO-ENEMIES-027
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
date: 2026-08-14
depends-on: [STO-ENEMIES-024]
bd-id: delve-vpd8
---

# The spider clambers over things, but walls stop it

## Summary

The spider **climbs over things in its way** — a crate, a low ledge, a
short pillar. It works out for itself how to get over them
(procedurally), so cover you hide behind is not safe.

But it **cannot climb giant things**. A proper wall stops it. It has to
go around, the same as you would.

This **changes** [STO-ENEMIES-024](./story-024-wall-climb.md), which
let it climb *anything* static. That made the big wall pointless. The
new rule is about size: **small enough to get over, or too big to
bother.**

## The rule, in plain words

The spider looks at whatever is in front of it and asks one question:
**can I see the top of this from here?**

- **Yes** -> it is a *thing*. Clamber over it.
- **No** -> it is a *wall*. Stay on the ground and go around.

That is one measurement, and it is the whole feature. Nothing needs a
list of what counts as a crate and what counts as a wall — the world
answers the question by itself. A new obstacle nobody thought about
gets the right behaviour for free.

## How big is "too big"

The cut-off is **the spider's own body height** — how high its block
rides above the ground on those long legs. If the top of the obstacle
is at or below that, its legs can reach over. If it is higher, it
cannot.

This is the right number because it is not a made-up one: it is the
creature's actual reach, so if the spider is ever made taller or
shorter the rule follows along without being re-tuned.

Playground reference points:

| Thing | Height | Expected |
|---|---|---|
| Crate | 0.8 m | clambers over |
| Short pillars | varies | over the short ones, not the tall |
| The big wall | 10.0 m | **blocked** |

## Definition of Done

- [x] Meeting a crate, the spider gets over it and keeps chasing.
- [x] Meeting the big wall, it does **not** go up. It stays on the
      ground.
- [x] Blocked by a wall, it **goes around** rather than pressing into
      it — it keeps hunting you instead of standing there looking
      stupid. (Operator's call, 2026-08-14.)
- [x] The judgement is measured from the world, not a hard-coded list
      of obstacle names.
- [x] The cut-off comes from the spider's own body height, not a magic
      number typed in by hand.
- [x] It still falls when knocked down — clambering must not make it
      immune to being ragdolled.
- [x] Walkers still do not climb at all.
- [x] Proven by a headless test that measures **both** cases: height
      gained over the crate, and height NOT gained at the wall.
- [x] The test has teeth — checked by disabling the fix and confirming
      the test fails.

## What it took (2026-08-14)

Measured, not guessed:

- **Spider reach 3.12 m** (its own body height, read off the creature).
- **Crate 1.2 m -> climbs.** Settles at 0.59, peaks at **1.20** — the
  exact top of the crate. It gets *onto* it, not merely near it.
- **Wall 10.0 m -> blocked.** Gains 0.12 m, never reports climbing, and
  does report skirting: it turns and goes around.

Both halves are asserted on the **same creature in one run**, because
"it does not climb the wall" is trivially passed by a spider whose
climbing is simply broken. The crate case has to pass first for the
wall case to mean anything.

### The bug that made this worth testing

The first version found the wall and missed the crate entirely. The
obstacle probe fired a single ray at **0.6 m** — a sensible height for
a human-sized enemy, and useless on a creature that stands **3.12 m**
tall. It sailed clean over every crate in the game, so the spider
reported open ground while walking face-first into a box. It could only
ever see obstacles *taller than itself*, which is precisely backwards
from what this story asks for.

Fixed by probing at shin height first (0.35 m), with the old height
kept as a backstop.

### The test has teeth (checked, not assumed)

Verified in **both** directions by breaking the rule on purpose:

| Sabotage | Result |
|---|---|
| climb *everything* (the old behaviour) | **4 failures** — wall gain 6.42 m |
| climb *nothing* | **3 failures** — crate gain 0.00 m |
| the real code | **PASS** |

One-directional teeth would not have been enough here: a test that only
catches "climbs too much" is passed perfectly by a spider that cannot
climb at all.

Full suite after the change: **pass=49 fail=0**, 24 skipped because the
operator's game held the multiplayer port (STO-TOOLS-009).

## Out of scope

- Ceilings, or hanging upside down.
- Climbing while carrying something.
- Making the *animation* of clambering look good. This story is about
  where it can and cannot go. Legs looking right on the way over is a
  separate job.

## Why this supersedes the old climb

STO-ENEMIES-024 is left in place and honest — it records that wall
climbing worked (y 1.0 -> 3.3) and then stalled partway up. That stall
is now **moot**: the wall it stalled on is exactly the kind of thing it
is no longer supposed to climb. This story replaces the behaviour
rather than fixing the stall.
