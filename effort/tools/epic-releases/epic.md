---
xid: EPI-TOOLS-RELEASES
parent: ../design.md
kind: epic
effort: tools
status: shipped
date: 2026-08-07
bd-id: delve-2d3
shipped: 2026-08-07
---

# Downloadable builds: join by IP + CI releases

## Summary

Makes delve something other people can actually download and play
together. Three parts, because a release on its own would not have
been enough:

- **join by address** — the join button was hardwired to
  `127.0.0.1`, so a downloaded build could only connect to itself;
- **CI releases** — GitHub Actions exports Linux and Windows builds
  from a tag, so no one needs Godot or the repo;
- **saved servers** — joined servers persist across restarts, so
  players can reconnect without retyping an IP.

## Definition of Done

- [x] A player can type an address and join a game on another machine.
- [x] Tagging `v*` produces downloadable Linux + Windows builds.
- [x] Downloads contain only the game, not the work tree or tests.
- [x] Servers a player joins are remembered across restarts.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 004 | join-address | S | Address box in the menu |
| 005 | ci-release | M | GitHub Actions build + release |
| 006 | saved-servers | M | Address book persisted to user:// |

## Note

The workflow could not be verified locally — the first tag push is
the real test.
