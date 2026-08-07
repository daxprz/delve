---
xid: STO-CORE-006
parent: ./epic.md
kind: story
effort: core
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-8up
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Everyone plays the same generated map

## Summary

Found while investigating the enemy desync, and arguably worse: the
maze seed came from `randi()` in every instance's `_ready`, so **host
and client generated completely different mazes**. Players were
colliding with walls their friend could not see.

**Fix:** the server sends its seed to each peer as it joins, and the
client rebuilds the maze from it — replacing the one it made on its
own — before its player appears.

## Definition of Done

- [x] The map seed is readable and the maze rebuildable from a seed.
- [x] The server sends its seed on peer connect.
- [x] A joining client adopts it and discards its own maze.
- [x] Rebuilding leaves exactly one maze in the scene.
- [x] Single-player still gets a fresh random maze each run.

## Out of scope

- Seeding the playground or mirror (both are deterministic already).

## Verification notes (2026-08-07)

- Two live instances reported the identical seed (2069579958) after
  the client joined, where previously each rolled its own.
- Guarded structurally in `tests/smoke_world_sync.gd`, including that
  a rebuild does not leave two mazes stacked in the scene — the first
  attempt did, because Godot frees deferred and the old node still
  held the name.
