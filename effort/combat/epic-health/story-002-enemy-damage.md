---
xid: STO-COMBAT-002
parent: ./epic.md
kind: story
effort: combat
size: S
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-nw6
tasks: 2
complete: 2
---

# Enemies hurt the player on contact; dying respawns you

## Summary

The follower enemies now **hurt the player on contact** — get too close
and they chip away your health. If your health hits **0 you respawn** at
your start point with full health.

## Definition of Done

- [x] An enemy touching the player deals damage over time.
- [x] Dying (health 0) respawns the player at full health.

## Verification notes (2026-08-03)

- `enemy.gd`: within `ATTACK_RANGE` (1.5 m) it calls `take_damage`
  (`ATTACK_DPS` 18/s) on the nearest player (server-authoritative; skips
  while staggered from a punch).
- `player.gd`: `take_damage` clamps to 0 and calls `_respawn` (reset
  health + move to the spawn position).
- `tests/smoke_health.gd`: **RESULT: PASS** — an enemy placed next to the
  player dropped its health (140 → 128), and lethal damage respawned at
  full health.

### Change 2026-08-03 — enemies no longer deal damage

- [x] Operator asked to make enemies unable to deal damage. Removed the
      enemy contact-damage code (`ATTACK_RANGE` / `ATTACK_DPS` and the
      `take_damage` call in `enemy.gd`). Enemies now **only chase**. The
      health infrastructure stays — `take_damage()` / `_respawn()` and
      the health bar remain for future damage sources. `smoke_health.gd`
      updated to assert an enemy on contact does **no** damage: **RESULT:
      PASS.**

## Out of scope

- Enemy attack animations / knockback of the player; enemies having their
  own health to be defeated; multiplayer damage authority.
