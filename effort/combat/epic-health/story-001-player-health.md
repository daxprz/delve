---
xid: STO-COMBAT-001
parent: ./epic.md
kind: story
effort: combat
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-glg
tasks: 3
complete: 3
---

# Players have health (Grabber more than Runner) + a health bar

## Summary

Every character has a **max health** from its def — the **Grabber (140)
is tougher than the Runner (80)**. Players start at full health, and a
**health bar** in the corner shows how much is left.

## Definition of Done

- [x] Health comes from the character def; Grabber has more than Runner.
- [x] Players start at full health.
- [x] A health bar shows the owner's current health.

## Verification notes (2026-08-03)

- `characters.gd`: `health` — Grabber 140, Runner 80.
- `player.gd`: `_max_health` / `_health` from the def; `health()` /
  `max_health()`; `take_damage()`; a `CanvasLayer` HUD with a red fill
  bar built for the authority and updated in `_process`.
- `tests/smoke_health.gd`: **RESULT: PASS** — Grabber 140 > Runner 80,
  starts full, damage lowers it.

## Out of scope

- Health regen; damage numbers / hit flashes; health pickups.
