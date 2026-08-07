---
xid: STO-TOOLS-006
parent: ./epic.md
kind: story
effort: tools
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-jea
shipped: 2026-08-07
tasks: 6
complete: 6
---

# Saved servers that persist across restarts

## Summary

Servers you join are remembered and survive restarts, so people can
reconnect later without retyping an IP address.

`Network` keeps a short address book in `user://servers.json`
(most-recent-first, capped at 8). Joining remembers or bumps a server;
the menu lists them as buttons — click to join, small **x** to forget.
Loading is forgiving about a hand-edited or older file rather than
losing the lot.

## Definition of Done

- [x] Joining remembers the server.
- [x] Saved servers survive a restart (written to and read from disk).
- [x] Re-joining bumps rather than duplicates.
- [x] The menu lists saved servers; clicking one joins it.
- [x] A server can be forgotten, and that persists too.
- [x] `tests/smoke_saved_servers.gd` passes headless (13 checks).

## Out of scope

- Naming a server from the UI (the field exists and persists, but
  nothing sets it yet).
- Checking whether a saved server is currently up.

## Verification notes (2026-08-07)

- 13/13 PASS. Persistence is proven the honest way: write, wipe the
  in-memory list, then reload from disk — the same path a fresh launch
  takes — rather than just reading back the variable we set.
