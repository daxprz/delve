---
xid: STO-COMBAT-003
parent: ./epic.md
kind: story
effort: combat
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-909
tasks: 3
complete: 3
---

# A combo meter: chained hits multiply damage (air-chain bonus)

## Summary

Chaining hits builds a **combo** that **multiplies your damage** — every
enemy you hit in quick succession makes the next hit stronger. Being
**airborne** while you hit adds a bonus (rewards swinging / flying /
wall-jumping between hits). The combo **resets** if you don't land a hit
for a couple of seconds, or if you get hit.

## Definition of Done

- [x] Consecutive enemy hits raise a combo level that scales damage.
- [x] Airborne hits get an extra multiplier (flow bonus).
- [x] Combo resets after `COMBO_WINDOW` with no hit, or when you're hurt.

## Verification notes (2026-08-03)

- `player.gd` `deal_damage(target, amount)`: multiplier =
  `1 + combo*COMBO_STEP` (×`COMBO_AIR_BONUS` while airborne); increments
  the combo and refreshes its timer; `take_damage` resets it; the timer
  decays each tick.
- All player attacks route through it: the arm **ram** (`mechanical_arms`),
  the **tail** whip (`tail.gd`), and **shockwaves** (`shockwave.gd` gains
  a `source` player so its damage counts too).
- The on-screen combo text was removed at the operator's request.
- `tests/smoke_combo.gd`: **RESULT: PASS** — two equal hits did 15 then
  20.3 damage (the combo multiplied), and the combo reset after ~2 s.

## Out of scope

- Combo UI / style ranks; combo-gated special finishers.
