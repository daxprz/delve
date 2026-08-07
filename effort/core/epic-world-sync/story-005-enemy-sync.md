---
xid: STO-CORE-005
parent: ./epic.md
kind: story
effort: core
size: L
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-o1s
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Enemies are server-owned and replicated

## Summary

**Bug (reported by the operator):** enemies were not multiplayer
entities at all. Every instance built its own set from a script in
`_ready`, and since enemy AI only runs on the server, a client's
copies were private ghosts that stood frozen wherever they spawned.
Nothing about them agreed between machines.

**Fix:** enemies are now instanced from `scenes/enemy.tscn` into a
container watched by a `MultiplayerSpawner`, so the server's enemies
replicate to every peer including late joiners, and each carries a
`MultiplayerSynchronizer` for position and rotation. A client bins
whatever it built locally the moment it joins.

## Definition of Done

- [x] Enemies come from a scene (a script-built node can never
      replicate).
- [x] A spawner replicates them from the server.
- [x] Each enemy synchronizes position and rotation.
- [x] A joining client discards its local enemies.
- [x] `tests/smoke_world_sync.gd` guards the structure; live two-
      instance run verifies the behaviour.

## Out of scope

- Replicating ragdolls. A client currently sees a knocked-down enemy
  glide rather than tumble, because ragdoll parts are built locally
  on impact. Worth its own story.
- Syncing enemy health.

## Verification notes (2026-08-07)

- Two live instances: all three enemies matched exactly on both sides
  at spawn, and while chasing, host and client converged to identical
  positions (17.4532165527344 on both) — with a brief lag visible on
  the first sample, which is ordinary network interpolation.
