---
xid: STO-UI-004
parent: ./epic.md
kind: story
effort: ui
size: L
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-1e1
shipped: 2026-08-07
tasks: 8
complete: 8
---

# A lobby before the game starts

## Summary

Host and Join used to drop you straight into the world, alone, with no
way to tell whether anyone else had arrived. Now everyone gathers in a
**lobby** first: you see who is here and what they are playing, you
can change your character while you wait, and the host decides when to
begin.

Joining a game that is **already running** skips the lobby entirely
and drops you in.

## Definition of Done

- [x] Hosting opens a lobby rather than starting the game.
- [x] The lobby lists everyone and their chosen character, agreeing on
      every machine.
- [x] Character choices propagate to all peers.
- [x] Only the host can start; everyone leaves the lobby together.
- [x] The cursor is free in the lobby and locks on start.
- [x] Joining a running game skips the lobby.
- [x] `--server` skips the lobby (automation wants to play).
- [x] `tests/smoke_lobby.gd` passes (16 checks).

## Out of scope

- Ready-up checkboxes, kicking players, or a chat box.

## Verification notes (2026-08-07)

- Verified with two live instances: both sides listed the same two
  players; the client picked the Sniper and the host's lobby showed
  it; on start both left the lobby together and spawned as the right
  characters (host grabber, client sniper, 65 hp).
- **A bug this found:** a client joining a game already in progress
  had its player spawned by the host but sat on its own lobby screen
  forever, because nothing told it the game was running. The host now
  sends `_begin_game` to late joiners.
- **A second bug, caught by the multiplayer test:** assigning
  `button_pressed` re-emits a Button's signals, so refreshing the
  character rows re-entered `_choose_character` and respawned the
  player continuously. With three rows now (menu, lobby, pause) it
  fired constantly. Fixed with `set_pressed_no_signal`.
