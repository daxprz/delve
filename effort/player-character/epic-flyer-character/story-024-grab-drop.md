---
xid: STO-CHARACTER-024
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-dmp
tasks: 3
complete: 3
---

# LMB+RMB grabs an enemy; dropping it deals fall damage

## Summary

Hold **LMB + RMB together** to **grab the nearest enemy** in the Flyer's
talons and carry it. Fly up high, then **let go to drop it** — the enemy
falls and takes **fall damage** on landing, badly hurting or **killing**
it if dropped from high enough.

## Definition of Done

- [x] LMB+RMB grabs the nearest enemy and carries it below the player.
- [x] Releasing drops the enemy (it falls under gravity).
- [x] A dropped enemy takes fall damage (more from higher = death).

## Verification notes (2026-08-03)

- `player.gd`: `_do_carry` — while both mouse buttons are held, grabs the
  nearest enemy (`CARRY_RANGE`), calls `set_carried(true)`, and pins it
  below the player; on release, `set_carried(false)` drops it.
- `enemy.gd`: `_carried` freezes AI/gravity while held; and enemies now
  take **fall damage** when they land faster than `FALL_SAFE_SPEED`
  (`take_damage((speed - safe) * scale)`).
- `tests/smoke_flyer.gd`: **RESULT: PASS** — LMB+RMB grabbed an enemy, and
  dropping it from ~15 m hurt/killed it.

### Change 2026-08-03 — carried enemy dangles

- [x] The carried enemy now **dangles on a rope** below the player (a
      small verlet swing that reacts to your movement) instead of being
      rigidly pinned. `player.gd` `_do_carry` runs a mini pendulum
      constrained to `CARRY_ROPE` below the player.

## Out of scope

- Throwing the enemy; carrying rigid bodies / the box; MP authority.
