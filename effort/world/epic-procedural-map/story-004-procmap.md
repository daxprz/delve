---
xid: STO-WORLD-004
parent: ./epic.md
kind: story
effort: world
size: L
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-zzy
tasks: 4
complete: 4
---

# A procedural maze map: long hallways + climbing, separate from the playground

## Summary

A **procedurally generated maze map**: a randomized-DFS maze over a grid
of small cells makes **long winding hallways** that are **compact** (tight
corridors, not spacious). Scattered **climb features** (stepped platforms)
give things to climb up. The layout is **random each play** (seeded) but
reproducible for a given seed. It lives in its **own region**, apart from
the playground/testing area.

## Definition of Done

- [x] Maze generated procedurally (randomized DFS), seedable + random
      each play.
- [x] Compact, corridor-like layout (long hallways, not spacious).
- [x] Climb features (stepped platforms) to go up.
- [x] Placed in its own area, separate from the playground.

## Verification notes (2026-08-03)

- `scripts/procmap.gd` (`ProcMap`): randomized-DFS carves passages over a
  6x6 grid of 5 m cells; builds the remaining internal + outer walls
  (with an entrance gap) and 4 stepped climb platforms; a `map_seed`
  (set to `randi()` by `main.gd`) makes it random each run. Placed at an
  offset (own region); ground grown to 120 x 120. The old hand-built
  `buildings.gd` / `smoke_buildings.gd` were removed.
- `tests/smoke_procmap.gd`: **RESULT: PASS** — ~30 walls + 4 climb
  features; different seeds give different layouts (procedural); the same
  seed reproduces the same layout (deterministic); and the ProcMap is a
  separate node from the Playground.

### Change 2026-08-03 — rooms (not corridors), no stairs, upper areas

- [x] Operator wanted distinct **rooms** (not open maze corridors), **no
      stairs**, and rooms with **areas to go up higher**. Reworked: walls
      between rooms now keep a **doorway gap** (connected) or stay solid
      (unconnected), so each cell is a real room; a few extra doorways add
      loops. Bigger rooms (grid 5x5, cell 7 m). Removed the stair climb
      features; instead a few rooms get an **upper platform** (a raised
      partial floor + a low ledge) you climb to with jump / wall-jump /
      grapple — no stairs.
- `tests/smoke_procmap.gd`: **RESULT: PASS** — ~70 wall segments (rooms
  with doorways) + 3 upper areas; still procedural + deterministic +
  separate.

## Out of scope

- Guaranteed vertical progression / multi-floor maze; decorating rooms;
  connecting the maze region to the playground with a path.
