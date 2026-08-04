---
xid: STO-ENEMIES-002
parent: ./epic.md
kind: story
effort: enemies
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-5l9
tasks: 3
complete: 3
---

# Enemies have health and can be defeated by punches/shockwaves

## Summary

Enemies get their **own health** (60) and can be **defeated**. The
Grabber's **punch damages them** (scaled by punch power / momentum — a
fast punch hits hard), and its **shockwave** damages everything nearby.
Hit enemies **flash white**; at 0 health they're **removed**. So you can
actually fight back and clear them out.

## Definition of Done

- [x] Enemies have health and a `take_damage()`; they flash when hit.
- [x] At 0 health the enemy is defeated (removed from the game).
- [x] Punches damage enemies (more momentum = more damage); shockwaves
      damage all nearby enemies.

## Verification notes (2026-08-03)

- `enemy.gd`: `MAX_HEALTH` 60, `_health`, `take_damage()` (white flash +
  `queue_free` at 0), `health()` / `max_health()`.
- `mechanical_arms.gd`: on a connecting punch, also calls `take_damage`
  = `power * PUNCH_DAMAGE` (1.6) on anything with health.
- `shockwave.gd`: calls `take_damage(power)` on each affected body.
- `tests/smoke_enemy_health.gd`: **RESULT: PASS** — enemies start at 60,
  `take_damage` lowers it, lethal damage frees the enemy, and a strong
  punch dropped one 60 → 5.

## Out of scope

- Enemy health bars; death effects (ragdoll/particles); XP/score; enemies
  respawning over time.
