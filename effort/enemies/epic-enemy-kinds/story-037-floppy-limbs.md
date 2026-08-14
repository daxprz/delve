---
xid: STO-ENEMIES-037
parent: ./epic.md
kind: story
effort: enemies
size: M
status: superseded
date: 2026-08-14
depends-on: [STO-ENEMIES-030]
bd-id: delve-fl0p
---

# The spider's legs and pincers are floppy

> **NOT ACTUALLY FLOPPY IN PLAY (2026-08-14).** The operator looked at
> it and said it "isn't flopy in any way". They were right, and this
> story's own tests said otherwise.
>
> Measured on a spider walking normally at its real speed of 1.6 m/s:
>
> ```
> flop = 1.4 deg  ->  0.3  ->  0.1  ->  0.0
> ```
>
> **1.4 degrees at the peak, decaying to nothing.** Invisible.
>
> The mechanism below works exactly as written. It is attached to the
> wrong thing: lag is driven by CHANGES in the body's velocity, and a
> creature walking in a steady line has none. The tests only ever
> produced a number because they shoved the spider at **14 m/s** —
> roughly nine times its walking speed, and something that never
> happens in play.
>
> The DoD was the deeper fault. Every line of it was satisfiable by a
> mechanism nobody could see, because not one line asked whether the
> floppiness was **visible while the spider was doing its ordinary
> thing**. Superseded by STO-ENEMIES-039.

## Summary

The spider's limbs stop being a rigid frame. They **trail, swing and
overshoot** — long loose limbs slung off a body that is dragging them
around, rather than a machine with everything bolted where it belongs.

And when something hits it, a limb **goes limp**: it stops driving and
just dangles for a moment before it gathers itself back up.

## What the operator asked for (2026-08-14)

Both of the floppy options, combined:

- **Very loose and rubbery.** Big lazy swings, limbs trailing well
  behind the body. Alien-looking on purpose.
- **And it can go limp.** A hit makes a limb genuinely stop working for
  a moment.

That combination is the interesting one, because the second is only
readable *because* of the first. If the limbs were stiff, a limp limb
would look like a bug. Since they are already swinging loosely, a limb
that stops swinging **reads as damage** without anything having to
explain it.

## The rule

Floppiness is **driven by the creature's own movement**, not by a
looping animation. When the spider accelerates, turns or stops, its
limbs lag behind and then catch up, overshooting slightly on the way.
A spider standing perfectly still has still limbs.

That is the same principle its gait already follows — motion derived
from what the body is actually doing — and it is what stops the
floppiness reading as a wobble effect pasted on top.

## Definition of Done

- [x] Limbs lag behind when the spider starts, stops or turns.
- [x] They overshoot and settle rather than snapping into place.
- [x] Segments further from the body swing **more** than those close to
      it, the way a long loose limb does.
- [x] A standing-still spider's limbs are still — the floppiness comes
      from movement, not a timer.
- [x] Being hit makes a limb go limp and dangle, then recover.
- [x] The gait still works: it walks, clambers, and does not fall over
      because of it.
- [x] Pincer arms are floppy too, not just legs.
- [x] Proven by a headless test that measures lag against a **still**
      spider, so "it moved" cannot pass for "it flopped".

## What it took (2026-08-14)

Three attempts at the same question — *what should the limbs lag
behind?* — and the first two produced numbers that looked like data and
were noise.

### Attempt 1: acceleration, sampled on the render frame

A spider standing perfectly still measured **0.0325 rad** of lag.

Position only changes when PHYSICS runs. Sampled from `_process`, a
render frame with no physics tick inside it sees the creature as
stationary and the next one sees it jump — so velocity alternated
between zero and a lurch.

### Attempt 2: acceleration, sampled on the physics tick

**0.0712 rad.** Worse.

The real fault was never the sampling rate: it was reaching
acceleration by differencing position **twice**. Each derivative
multiplies noise by `1/delta`, so at 60 Hz a single millimetre of
physics jitter comes out as **3.6 m/s²** — and at 0.085 rad per m/s²
that is a third of a radian of pure garbage.

### What works: velocity, taken from the creature itself

The parent is a `CharacterBody3D` and already knows its own velocity,
so nothing needs differencing at all. Lag is driven by how far that
velocity has run ahead of a **smoothed** copy of itself — which is
exactly what starting, stopping and turning look like, and what steady
travel does not.

One derivative instead of two, bounded by real speed:

| | Lag |
|---|---|
| standing still | **0.0039 rad** |
| shoved sideways | 0.0530 rad, joints swinging 0.65 rad |
| settled again | 0.0115 rad |

### The test was wrong twice as well

- **The "shove" ragdolled the spider.** `apply_knockback` hard enough
  to lurch it (dv 40) is far past the knockdown threshold (7.5), and a
  ragdolled enemy has its velocity zeroed every tick — so the phase was
  measuring a creature lying perfectly still. Driven by velocity now,
  and it asserts the spider did *not* go down.
- **"Settled" read higher than the shove.** Left to coast, friction
  bleeds speed off at a steady rate, and steadily losing speed IS a
  change in velocity, so the limbs correctly kept trailing. A
  decelerating spider is not a settled one. It is brought to a real
  stop first.

### Teeth

| Sabotage | Result |
|---|---|
| floppiness off | **2 failures**, 0.0000 rad both cases |
| limp disabled | **1 failure**, limpness 0.00 |
| real code | PASS |

### One thing deliberately left alone

The pincers keep the idle weave they were given in STO-ENEMIES-030, so
the *arms* still move on a standing spider even though its *legs* go
still. That is on purpose — the weave is the creature's menace, and the
DoD line about stillness is asserted against the legs.

Full suite: **pass=52 fail=0**, 24 skipped for the port.

## Out of scope

- Real rigid-body physics on the limbs. The spider already becomes a
  true ragdoll when it is knocked down; this is about how it moves
  while it is still standing.
- Limbs colliding with the world while they swing.
