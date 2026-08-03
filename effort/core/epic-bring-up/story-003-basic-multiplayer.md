---
xid: STO-CORE-003
parent: ./epic.md
kind: story
effort: core
size: M
status: shipped
date: 2026-08-03
depends-on: [STO-CORE-002]
bd-id: delve-e7g
shipped: 2026-08-03
tasks: 5
complete: 5
---

# Basic multiplayer: host, join, see other players move

## Summary

Two instances of delve playing together over localhost using Godot's
high-level multiplayer: `ENetMultiplayerPeer` for transport, a
`MultiplayerSpawner` to instance a player per connected peer, and a
`MultiplayerSynchronizer` replicating each player's transform. Each
peer has authority over its own player; a minimal host/join affordance
(bare UI or `--server`/`--client` launch args) selects the role.

## Definition of Done

- [x] A network autoload (`scripts/autoload/network.gd`) can host on
      port 7777 and join `127.0.0.1`.
- [x] Minimal host/join affordance at launch (menu buttons AND
      `-- --server` / `-- --client` launch args).
- [x] MultiplayerSpawner spawns a player node per peer (and despawns
      on disconnect); each peer only controls its own player.
- [x] Transform sync: on two local instances, each player sees the
      other move and jump in real time.
- [x] Input/camera code runs only for the owning peer (no fighting
      over the remote player's camera).

## Verification notes (2026-08-03)

- `scripts/run_mp_test.sh` runs two headless instances
  (`tests/smoke_mp_host.gd` + `tests/smoke_mp_client.gd`). All PASS:
  peer connects, player spawns under `Players/<peer-id>`, client-side
  input moves the client's player (dz=-5.44 locally), and that
  movement replicates to the host (host observed dz=-1.00 → threshold
  crossed), clean disconnect.
- Architecture: server-authoritative spawning (main.gd), node name =
  peer id → `set_multiplayer_authority(name.to_int())` in
  `player.gd._enter_tree`; MultiplayerSynchronizer replicates
  position+rotation; non-authority peers skip input/physics and their
  camera is not current.
- Gotchas hit and encoded in tests (also in agent memory):
  (1) under `godot -s`, autoloads join the tree only AFTER
  `_initialize` — all test setup runs on the first physics tick;
  (2) in two-process tests the HOST must outlive the client, else
  server teardown despawns replicated nodes mid-assertion.
- "Jump replicates" is covered by position sync (y is replicated);
  visual confirmation on two windowed instances still worth a manual
  run.

## Out of scope

- Internet play, NAT traversal, dedicated server, matchmaking.
- Player names, chat, disconnect UI polish, lag compensation.
