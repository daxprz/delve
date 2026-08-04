---
xid: STO-ENEMIES-001
parent: ./epic.md
kind: story
effort: enemies
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-bo2
tasks: 4
complete: 4
---

# An enemy that walks toward the player

## Summary

A simple enemy that **follows the player**. Each physics tick it finds
the nearest player and walks toward them (gravity keeps it grounded).
It stops when it reaches them. Deliberately simple — no attacking, no
health. Bonus: it reacts to the Grabber's punch/shockwave by getting
knocked back and briefly staggered, then resumes chasing.

## Definition of Done

- [x] Enemies spawn in the world (3 of them, at set positions).
- [x] An enemy walks toward the nearest player and closes the distance.
- [x] It stops when it's basically on top of the player.
- [x] A punch / shockwave knocks it back (then it chases again).

## Verification notes (2026-08-03)

- `scripts/enemy.gd` (`Enemy`, a `CharacterBody3D`): builds its body in
  code (red capsule + eyes); `_nearest_player()` scans the `players`
  group; steers toward it at `SPEED`; server-authoritative
  (`multiplayer.is_server()`). `apply_knockback()` adds an impulse +
  a brief stagger. Players join the `players` group in `player.gd`.
- Spawned by `main.gd` `_spawn_enemies()` under an `Enemies` node.
- Punch (`mechanical_arms.gd`) and shockwave (`shockwave.gd`) now also
  call `apply_knockback` on anything that has it (i.e. enemies).
- `tests/smoke_enemy.gd`: **RESULT: PASS** — 3 enemies spawn, one closed
  8.5 m → 5.5 m on the player, and a knockback shoved it back.

## Out of scope

- Enemies attacking / damaging the player, enemy health & dying,
  pathfinding around obstacles, and multiplayer replication of enemy
  motion (server-only for now) — all future stories.
