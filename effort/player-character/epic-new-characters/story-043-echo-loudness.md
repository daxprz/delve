---
xid: STO-CHARACTER-043
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-98u
shipped: 2026-08-07
tasks: 4
complete: 4
---

# Heavier creatures make louder echoes

## Summary

Heavier creatures now make **louder** echoes. A pulse's reach and
brightness scale with the mover's relative mass — which already comes
from its procedurally-generated build (STO-ENEMIES-005), so every
individual enemy is naturally a bit louder or quieter than the next.

For the Sniper this means footsteps carry information about *size*:
something big announces itself from much further away, while a small
one has to get close before you can read the room around it. It is the
first hint of "what" is out there, without ever outlining the creature
itself.

## Definition of Done

- [x] A heavy creature's echo reaches further than a light one's at
      the same speed.
- [x] A heavy creature's echo is brighter.
- [x] A light creature is still clearly visible (never silent).
- [x] Loudness reads the procedural build's relative mass, not
      RigidBody kilograms.

## Out of scope

- Loudness by material/surface (stone vs grass).
- Player-side loudness differences between characters.

## Verification notes (2026-08-07)

- Same speed (4 m/s), forced masses 0.8 vs 1.5: reach 8.1 m vs
  **15.1 m**, brightness 0.58 vs **1.00**. The light one stays well
  above the visibility floor.
- Deliberately does NOT read `RigidBody3D.mass`: that is in kilograms,
  a different scale from the enemies' relative build mass (~0.75–1.5),
  so a 2 kg crate would otherwise have out-shouted every enemy.
- 24/24 PASS in `tests/smoke_sniper_echo.gd`.
