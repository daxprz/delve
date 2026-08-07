---
xid: STO-TOOLS-004
parent: ./epic.md
kind: story
effort: tools
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-03t
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Join a game by typing an address

## Summary

The menu gains an address box, so you can join a game on another
machine. The join was hardwired to `127.0.0.1` — the network layer
took an address, but nothing ever passed one — so a downloaded build
could only ever connect to itself.

Defaults to `127.0.0.1` (same-machine play still works with no
typing), falls back to it if the box is left blank, and Enter in the
box joins. `-- --client <address>` also works for shortcuts.

## Definition of Done

- [x] An address box in the menu, with a hint of what to type.
- [x] Join uses the typed address.
- [x] Blank falls back to localhost rather than failing to connect.
- [x] `--client <address>` launch arg works.
- [x] `tests/smoke_join_address.gd` passes headless (6 checks).

## Out of scope

- Choosing a port (fixed at 7777).
- Discovering games on the local network automatically.

## Verification notes (2026-08-07)

- 6/6 PASS.
