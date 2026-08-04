---
xid: STO-CHARACTER-023
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-n66
tasks: 2
complete: 2
---

# Shift dive-bombs (fast dive + impact shockwave)

## Summary

While flying, hold **Shift to dive-bomb** — you plunge straight down fast.
Landing from a dive makes an **impact shockwave** that blasts nearby
enemies. Great for swooping down on a group.

## Definition of Done

- [x] Shift (while airborne + fuel) dives down fast.
- [x] Landing from a dive spawns a shockwave that damages nearby enemies.

## Verification notes (2026-08-03)

- `player.gd`: in `_fly_move`, `sprint` (Shift) sets `velocity.y =
  -DIVE_SPEED` (20) and flags `_was_diving`; on landing, `_dive_impact`
  spawns a `Shockwave` (`DIVE_IMPACT_POWER`) at the feet.
- `tests/smoke_flyer.gd`: **RESULT: PASS** — Shift gives a downward
  velocity of -20 m/s.

## Out of scope

- Damaging enemies you pass *through* mid-dive; screen shake.
