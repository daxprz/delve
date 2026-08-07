---
xid: STO-TOOLS-001
parent: ./epic.md
kind: story
effort: tools
size: M
status: shipped
date: 2026-08-06
depends-on: []
bd-id: delve-66a
shipped: 2026-08-06
tasks: 5
complete: 5
---

# RCON TCP server autoload

## Summary

`scripts/autoload/rcon.gd`: a TCPServer on port 9999 accepting
newline-delimited text commands from `nc`, with a dispatch table and
the core command set: `help`, `status`, `fps`, `rstat`, `players`,
`enemies`, `spawn enemy [x y z]`, `clear`, `tp <player> <x> <y> <z>`,
`eval <expr>`, `quit`. Port falls back upward (9999→10000…) when
taken so host+client instances coexist; `status` reports which port.

## Definition of Done

- [x] `echo "help" | nc -w2 localhost 9999` lists commands against a
      running instance.
- [x] `status` reports port, scene, peer count, player/enemy counts,
      fps.
- [x] `spawn enemy` / `clear` / `tp` / `eval` work against the live
      scene.
- [x] Two simultaneous instances each get a port; `status` shows it.
- [x] `tests/smoke_rcon.gd` drives the server over loopback TCP
      headless and passes.

## Verification notes (2026-08-06)

- `tests/smoke_rcon.gd`: 13/13 PASS over real loopback TCP
  (help/status/players/spawn/enemies/tp/eval/debug/clear + error
  paths).
- Live: launched headless `--server` instance, drove it with `nc` and
  `scripts/rcon.sh`; spawned/damaged enemies, read state, `quit`.
- Port fallback proven live: second (`--client`) instance bound
  10000; `rcon.sh -p 10000 status` showed `net(id=… peers=[1])
  players=2`.
- Gotcha: `get_tree().current_scene` is null under `-s` test runs —
  `_scene_root()` falls back to root's last child.

## Out of scope

- `debug …` commands (story-002).
- JSON test runner (`run <test>` / `suite`) — later epic.
