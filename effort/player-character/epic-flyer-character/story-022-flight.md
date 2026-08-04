---
xid: STO-CHARACTER-022
parent: ./epic.md
kind: story
effort: character
size: L
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-r9d
tasks: 4
complete: 4
---

# Flyer with wings can fly for 30s (fuel), then must land to recharge

## Summary

The **Flyer** has **wings** and can **fly**. Hold **jump to flap upward**,
release to **glide** down slowly, and steer with WASD — full aerial
freedom. Flight is limited by a **fuel meter (~5 seconds)** shown as a
blue bar; it **drains while flying and recharges when you're on the
ground**. Out of fuel, you fall like anyone else and have to land.

## Definition of Done

- [x] Flyer character with procedural wings (no arms/tail).
- [x] Flap up / glide / steer while airborne; 5s of flight fuel.
- [x] Fuel drains flying, recharges on the ground; empty = you fall.
- [x] A fuel bar shows how much flight is left.

## Verification notes (2026-08-03)

- `characters.gd`: "flyer" def (`fly`, `wings`, `carry`).
- `scripts/wings.gd` (`Wings`): two flapping fans of feathers, fade
  shader; flap faster when rising.
- `player.gd`: `_fly_move` — airborne, `jump` flaps (`FLY_ASCEND`), Shift
  dives, else glides; drains `_fly_fuel` (`FLY_MAX_FUEL` 5), recharges on
  floor; a blue fuel bar in the HUD.
- `tests/smoke_flyer.gd`: **RESULT: PASS** — flapping climbs 2.5 m and
  drains fuel; out of fuel the Flyer falls.

## Out of scope

- Stamina-free flight / perches; wing collision.
