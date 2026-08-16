---
xid: STO-CHARACTER-021
parent: ./epic.md
kind: story
effort: character
size: M
status: removed
date: 2026-08-03
depends-on: []
bd-id: delve-341
tasks: 3
complete: 3
---

# Punch mode: hold to stick the arm out and ram enemies (momentum = damage)

## ⛔ REMOVED from the Grabber (2026-08-16)

The Grabber was remastered into a claw-machine claw
(EPI-CHARACTER-GRABBER-CLAW) and every one of its abilities was taken
out at the operator's request — four abilities, four keys and seven
unfinished piston stories traded for one idea a child can describe in
a sentence.

**This story is kept, not deleted**, the way the Guardian and Builder
were. What it measured and the bugs it found outlive the feature.

## Summary

Punch mode no longer throws a jab. Instead, **holding the button sticks
the fist straight out** in front, and **running that extended fist into
an enemy deals damage scaled by your momentum** — the faster you're
moving, the harder the hit. So you swing on the grapple to build speed,
hold the arm out, and **ram** through enemies. A fast enough ram still
makes a shockwave.

## Definition of Done

- [x] Holding LMB/RMB in punch mode sticks that fist straight out (no
      jab).
- [x] An extended fist that touches an enemy while moving deals damage
      scaled by momentum (no momentum = no damage).
- [x] A fast enough ram makes a shockwave.

## Verification notes (2026-08-03)

- `mechanical_arms.gd`: replaced the jab (`punch` / `try_punch` /
  cooldown) with an **extend** state — in punch mode the fist target is
  `_reach_point` (straight forward, arm's length) while the button is
  held. `_ram_damage` (each tick) checks each extended fist against
  enemies in the `enemies` group: if the player's speed ≥ `RAM_MIN_SPEED`
  and the fist is within `RAM_HIT_RADIUS`, it calls `take_damage`
  (`speed * RAM_DAMAGE_SCALE`) + knockback, and spawns a shockwave above
  `RAM_SHOCKWAVE_SPEED`. Per-enemy cooldown so one ram ≈ one hit.
- `tests/smoke_punch.gd`: **RESULT: PASS** — holding sticks the fist out;
  a no-momentum ram does no damage; a fast ram defeated the enemy and
  made a shockwave.

## Out of scope

- Ramming the box / rigid bodies (the ram only damages enemies now);
  multiplayer damage authority.
