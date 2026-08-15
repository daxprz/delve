---
xid: STO-ENEMIES-038
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-rdr1
---

# The spider feels for hitboxes to find you

## Summary

The spider stops being omniscient. Instead of simply knowing where
every player is, it **sweeps for them** — feeling out the hitboxes
around it — and when it finds one it **remembers where you were**.

## What the operator asked for (2026-08-14)

> "it should be able to find the player and have some sort of memory of
> where the player is so it can find the player without knowing exactly
> where they are"

So there are two halves, and the memory is the important one:

- **Finding.** A radar sweep around the creature that picks up the
  hitboxes of things it could hunt.
- **Remembering.** Once it has found you it keeps a **last known
  place**. Break away and it does not instantly forget, and it does not
  instantly know either — it goes to **where you were** and looks.

## Why the memory is the whole point

Without memory, radar is just a worse version of what it already does:
lose line of sight and the spider stands still, which reads as broken.

With memory, breaking away is a real thing you can *do*. It comes for
your last known spot, and you have that long to be somewhere else.
That is a chase instead of a magnet — and it is what makes the rest of
this epic frightening rather than unfair, because being taken is
something you can see coming and try to avoid.

## The rule

1. Sweep for hitboxes within radar range.
2. Anything found becomes the current target, and its position is
   written down as the **last known place**.
3. Found nothing? Hunt the last known place instead.
4. Arrive there and still nothing? The trail is cold. Stop hunting.

## Definition of Done

- [x] The spider finds players by sweeping for hitboxes with a real
      shape query, not by being told. Range **26 m** — finite, which is
      the entire point.
- [x] It records a last known place whenever it senses one.
- [x] Losing you, it walks to that place rather than freezing. Proven:
      the target was moved 400 m away, the spider found nothing, and
      **still had the trail**.
- [x] Reaching it and finding nothing, the trail goes cold.
- [x] Sensing you again overwrites the memory.
- [x] It finds the practice dummy too.
- [x] Other enemies are unaffected — a Walker still looks up the
      nearest player, and only the quadruped is given a mind.
- [x] Proven by `tests/smoke_spider_mind.gd`, which checks the MEMORY:
      that it keeps hunting after the target is taken away.

## Out of scope

- Sound, smell, or being alerted by other spiders.
- Walls blocking the sweep. Whether the radar is fooled by cover is a
  separate question from whether it remembers, and mixing the two would
  make both hard to judge.
