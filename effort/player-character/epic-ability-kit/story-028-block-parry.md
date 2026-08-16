---
xid: STO-CHARACTER-028
parent: ./epic.md
kind: story
effort: character
size: M
status: removed
date: 2026-08-03
depends-on: []
bd-id: delve-72p
tasks: 2
complete: 2
---

# Grabber block/parry: hold to reduce damage, tap to shove

## ⛔ REMOVED from the Grabber (2026-08-16)

The Grabber was remastered into a claw-machine claw
(EPI-CHARACTER-GRABBER-CLAW) and every one of its abilities was taken
out at the operator's request — four abilities, four keys and seven
unfinished piston stories traded for one idea a child can describe in
a sentence.

**This story is kept, not deleted**, the way the Guardian and Builder
were. What it measured and the bugs it found outlive the feature.

## Summary

The Grabber uses **C** to defend: **holding** C **blocks** (incoming damage
is cut to 25%), and **tapping** C **parries** — a burst that shoves nearby
enemies away. Turns fights into more than "run away".

## Definition of Done

- [x] While the guard key is held, `take_damage` is multiplied by
      `BLOCK_REDUCE` (25%).
- [x] Pressing the guard key knocks back all enemies within `PARRY_RANGE`.

## Verification notes (2026-08-03)

- `player.gd`: `_update_abilities` sets `_blocking` from the held guard key and
  fires `do_parry()` on press. `take_damage` applies the block multiplier;
  `do_parry` applies outward `apply_knockback` to nearby enemies.
- `tests/smoke_abilities.gd`: **PASS** — 40 damage was cut to 10 while
  blocking, and a parry shoved an enemy away.

## Out of scope

- A timed "perfect parry" window / stun; a stamina cost for blocking.
- (Enemies don't deal contact damage yet, so blocking matters most against
  future damage sources; the parry-shove is useful today.)
