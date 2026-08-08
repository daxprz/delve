---
xid: DES-TOOLS-001
kind: design
effort: tools
status: open
date: 2026-08-06
bd-id: delve-1kv
---

# TUMU testing & diagnostics infrastructure

## Summary

delve's testing agent (ember) cannot see the screen — it "sees" the
game through textual debug output and drives it through commands.
This design stands up the TUMU (Test, Understand, Monitor, Utilize)
infrastructure proven in the sister `mdes` project: an RCON TCP
server for controlling a running game, and a centralized DebugOverlay
aspect registry so any feature can be made inspectable (visually and
textually) at runtime. Every complex feature built after this gets
debug aspects as it is built.

## Goals

- Control a running game instance from the shell:
  `echo "status" | nc -w2 localhost 9999`.
- Toggle per-aspect debug output (2-level `group/sub` tree) with
  independent VISUAL and TEXTUAL channels, per observer
  (human, test:<name>, script:<id>).
- Give existing systems (network, player, enemy) their first aspects.
- Keep the door open for the mdes-style JSON test runner (later epic).

## Architecture

Three autoloads (order matters):
1. `DebugOverlay` — aspect registry; observer-based filtering;
   `log()`, `should_draw()`, `vis()` hot-path API; profile persistence.
2. `DebugAspects` — registers all known aspects at startup (one place
   to see everything inspectable).
3. `Rcon` — TCPServer on port 9999 (falls back to 10000+ if taken, so
   host+client instances on one machine can both listen); newline-
   delimited text commands; command families: help/status/fps,
   debug …, players/enemies, spawn/clear/tp, eval, quit.

Differences from mdes deliberately kept: delve is 3D (positions are
Vector3; `rstat` reports the 3D camera), no in-game console yet
(textual output goes to stdout only), and the RCON command set starts
minimal.

## Open questions

- Whether the JSON-defined test runner (mdes `run <test>` / `suite`)
  lands as its own epic or grows out of the smoke-test corpus.
