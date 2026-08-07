---
xid: STO-CORE-004
parent: ./epic.md
kind: story
effort: core
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-po1
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Players spawn apart, not inside each other

## Summary

**Bug, found by running two real instances:** both players spawned on
the same marker and, instead of settling, climbed past **2.5 km and
still accelerating**.

**Cause:** a remote player's position comes from the network sync, so
it cannot be pushed aside. When two capsules overlap exactly, the only
escape is straight up — so each instance shoved its OWN player upward,
synced the higher position, and shoved the other one higher again.

**Fix — two parts, only one of which is the real guarantee:**

1. **Players no longer collide with each other** (collision
   exceptions, added on spawn). This is the actual fix: it also covers
   two players simply *walking* into each other, which spawn changes
   would never have addressed. Exceptions are used rather than physics
   layers so world, enemies, the tail's rays and the Sniper's echo all
   keep seeing players exactly as before.
2. **Arrivals are spread around the spawn point**, derived from the
   peer id so host and client agree without messaging. This is a
   nicety — players don't materialise inside each other — not a
   safety net.

## Definition of Done

- [x] Two overlapping players settle instead of launching.
- [x] No runaway climb over time.
- [x] Players still collide with the world and stand on the ground.
- [x] Arrivals are generally spread around the marker.
- [x] `tests/smoke_player_overlap.gd` and
      `tests/smoke_spawn_spread.gd` pass; MP test and regressions
      still pass.

## Out of scope

- Standing on another player's head (deliberately given up — it is
  what made the runaway possible).

## Verification notes (2026-08-07)

- Verified live with two real instances: both players now rest at
  y≈0.0000 and stay there, and both instances agree on every position.
  Two-way movement replication confirmed by teleporting each player
  and reading it back from the other instance.
- `smoke_player_overlap` was checked for teeth by removing the fix:
  the player is shoved to **2.80 m** without it, **0.00 m** with it.
- **A wrong turn worth recording:** the first fix was spawn spreading
  alone, first with 6 fixed slots and then with a hash-based
  continuous spread. Both were wrong — independent peers can always
  collide (4242 and 777 landed on the same slot; the hash version
  still clashed once in 500), and neither addressed players walking
  into each other. Chasing better hashing was iterating on the
  trigger instead of the mechanism. The spread test was then relaxed
  to claim only what it actually delivers.
