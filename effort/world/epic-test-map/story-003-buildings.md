---
xid: STO-WORLD-003
parent: ./epic.md
kind: story
effort: world
size: L
status: abandoned
date: 2026-08-03
depends-on: []
bd-id: delve-pa4
tasks: 4
complete: 4
---

# Buildings with rooms and hallways, and open outdoor areas

## Summary

A test map with **two buildings** made of walls: a big one with a
**central hallway and four rooms** (a doorway into each), and a smaller
one with a **hallway and two rooms**. The front of each building is a
doorway you enter through. They sit on the **enlarged open ground** with
the playground obstacles as another outdoor area — so there are indoor
(rooms/halls) and outdoor spaces.

## Definition of Done

- [x] A big building: central hallway + 4 rooms, each with a doorway.
- [x] A smaller building: hallway + 2 rooms.
- [x] Doorways are real openings you can walk through; walls are solid.
- [x] Ground enlarged (90 x 90) to hold the map + outdoor areas.

## Verification notes (2026-08-03)

- `scripts/buildings.gd` (`Buildings`): a `_wall(a, b, doors)` helper
  builds wall runs with doorway gaps (each door = [distance, width]);
  `_build_big` and `_build_small` lay out the two buildings. Spawned by
  `main.gd`. Ground in `main.tscn` grown to 90 x 90.
- `tests/smoke_buildings.gd`: **RESULT: PASS** — 22 wall segments built;
  a ray through the front doorway passes (open), a ray through a wall is
  blocked (solid), and a room doorway off the hallway is open.

## Out of scope

- Roofs / multiple floors / stairs; interior props and lighting;
  enemy pathfinding around walls (enemies still move straight at you).
