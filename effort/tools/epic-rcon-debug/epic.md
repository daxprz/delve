---
xid: EPI-TOOLS-RCON-DEBUG
parent: ../design.md
kind: epic
effort: tools
status: open
date: 2026-08-06
bd-id: delve-ock
---

# RCON server + debug overlay

## Summary

Delivers the two core TUMU autoloads from [DES-TOOLS-001](../design.md):
an RCON TCP server so a running delve instance can be driven from the
shell, and the DebugOverlay aspect registry so systems emit gated
debug output that tests and agents can read. Includes first aspects
for network / player / enemy systems and headless smoke tests for
both autoloads.

## Definition of Done

- [x] With the game running, `echo "status" | nc -w2 localhost 9999`
      returns game state (peers, players, enemies, fps).
- [x] `debug list` shows the registered aspect tree;
      `debug log <group>/<sub>` turns on textual output for it, and
      the affected system prints gated lines to stdout.
- [x] Two instances on one machine can both accept RCON (port
      fallback), so host+client MP sessions stay inspectable.
- [x] `tests/smoke_rcon.gd` and `tests/smoke_debug_overlay.gd` pass
      headless.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 001 | rcon-server | M | TCPServer autoload, command dispatch, core commands |
| 002 | debug-overlay | M | Aspect registry + observers, DebugAspects, RCON debug cmds, first aspects |
