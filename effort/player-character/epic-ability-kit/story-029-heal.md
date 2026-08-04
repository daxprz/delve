---
xid: STO-CHARACTER-029
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-7d8
tasks: 1
complete: 1
---

# All characters slowly heal over time

## Summary

**Every character** slowly **heals over time**. After a short lull with no
damage (`HEAL_DELAY`), health regenerates at `HEAL_RATE` back up to the
character's max — so you recover between fights instead of staying hurt.

## Definition of Done

- [x] After `HEAL_DELAY` seconds without taking damage, health regenerates
      toward max at `HEAL_RATE`; taking a hit restarts the delay.

## Verification notes (2026-08-03)

- `player.gd`: `_update_heal(delta)` runs every tick for all characters;
  `take_damage` sets `_regen_timer = HEAL_DELAY`, pausing regen after a hit.
- `tests/smoke_abilities.gd`: **PASS** — a Grabber set to 70 HP healed to 78
  over ~100 frames.

## Out of scope

- Regen upgrades / consumable heals; disabling regen on hard difficulties.
