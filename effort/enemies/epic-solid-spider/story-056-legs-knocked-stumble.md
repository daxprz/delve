---
xid: STO-ENEMIES-056
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
date: 2026-08-15
depends-on: []
bd-id: delve-e1x2
---

# Something hits its legs and it stumbles

## Summary

> "make it so if anything colides with the spiders legs then it
> stumbles" — operator, 2026-08-15

Something catches a leg and the creature **lurches**. Not a knockdown —
a stumble, the reaction it already has for a medium blow
(STO-ENEMIES-007), now triggered by the world rather than only by being
hit.

This is only possible because the legs became real physics
(STO-ENEMIES-055). A spider whose legs are ghosts has nothing to trip
over.

## The whole difficulty is telling a knock from the floor

A spider's feet are touching the ground **every moment it is
standing**. So "did something touch a leg?" answers yes for ever, and
the naive version leaves it stumbling permanently and never walking
anywhere.

Two rules settle it, and the second was needed only because the first
was not enough:

1. **The contact normal.** Standing on the floor pushes a leg straight
   up; walking into a wall pushes it sideways. A contact whose normal
   is mostly horizontal is something in the way.
2. **Feet do not count at all.** The normal alone failed: a foot
   pressed into the floor by the leg drive penetrates slightly, and the
   solver expels it through whichever face is nearest — often a SIDE
   face. So the ground kept reporting itself as a wall with a perfectly
   horizontal normal.

Excluding feet is also the better reading of what was asked. A foot on
the floor is not "something colliding with its legs"; a wall catching
it mid-shin is. The upper and lower segments are most of the leg and
are what an obstacle actually fouls.

## Definition of Done

- [x] Something catching a leg makes the spider stumble.
- [x] **Walking on open ground does NOT** — measured **0 knocks** over
      300 ticks of walking on empty floor. This is the load-bearing
      check and it runs first.
- [x] It lurches rather than falling over.
- [x] It does not stumble for ever. Pressed against a wall for 1200
      ticks it took **5–7 knocks — 0.006 per tick**, not one per frame.
- [x] Its own body and its own other legs never count as knocks.
- [x] Proven by `tests/smoke_spider_trip.gd`, negative case first.

## Three wrong turns

1. **It tripped over itself.** The kin list held the bones but not the
   creature they hang off, so its own legs kept catching its own body
   capsule — four knocks on empty ground.
2. **The "open ground" was a maze.** The test used `main.tscn`, which
   ships 71 procedural walls, so the spider met real obstacles and
   reported perfectly correct knocks that the test called false
   positives. It builds its own empty world now.
3. **The obstacle was one it climbs.** A 3 m wall is under the spider's
   body height, so it clambered over instead of being caught
   (STO-ENEMIES-027). Ten metres.

And the recovery check measured "does it keep moving" while the
creature was pressed against a wall **it is supposed to be stopped
by** — 0.21 / 0.39 / 0.54 / 0.13 m across runs, passing and failing on
nothing. It measures the knock RATE now, which is the thing actually
claimed.

## Out of scope

- Being knocked fully over by a leg hit. That stays a blow-only thing.
- The player deliberately tripping it. It happens if you get a leg,
  but no move exists for it.
