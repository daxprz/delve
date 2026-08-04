---
xid: STO-CHARACTER-018
parent: ./epic.md
kind: story
effort: character
size: L
status: abandoned
date: 2026-08-03
depends-on: []
bd-id: delve-2q4
tasks: 3
complete: 3
---

# A Spider character that climbs walls

## Summary

The **Spider** character sticks to walls and **climbs** them. Push into a
wall and it grabs on; then **W/S climb up/down**, **A/D crawl sideways**
along the wall (no gravity while stuck), and **jump leaps off**. Its own
distinct way to get around — great in the maze and up the big wall.

## Definition of Done

- [x] Pushing into a wall makes the Spider stick and climb (no falling).
- [x] Up/down/sideways movement on the wall; jump leaps off.
- [x] Only the Spider can wall-climb (other characters unaffected).

## Verification notes (2026-08-03)

- `characters.gd`: new "spider" def (`wall_climb: true`, `humanoid:
  false`, no arms/tail).
- `player.gd`: `_update_climb` grabs a wall when the movement input pushes
  into it (and stays stuck once climbing); `_climb_move` zeroes gravity
  and maps forward/back to up/down and strafe to along-wall, pushing into
  the wall (`WALL_STICK`) to stay attached; jump leaps off (reuses the
  wall-jump launch + lock).
- `tests/smoke_spider.gd`: **RESULT: PASS** — driven into the big wall,
  the Spider climbed **2.7 m up** instead of falling.

## Out of scope

- Ceiling crawling; auto-mounting the top of a wall onto its ledge.
