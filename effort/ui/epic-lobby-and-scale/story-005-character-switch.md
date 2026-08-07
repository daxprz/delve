---
xid: STO-UI-005
parent: ./epic.md
kind: story
effort: ui
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-d34
shipped: 2026-08-07
tasks: 6
complete: 6
---

# Change character easily, including mid-game

## Summary

Changing character used to mean going back to the main menu. Now the
same picker appears in the **main menu, the lobby and the pause
menu**, and choosing a different character mid-game respawns you as
it — no reconnecting.

This also fixed a bug nobody had reported: `character` was read from
the local menu selection inside the player, which only the owner knew,
so **every remote player appeared as the Grabber** whatever they had
picked. The choice now travels with the spawn, so everyone sees each
other correctly.

## Definition of Done

- [x] The character picker is available in menu, lobby and pause menu.
- [x] Choosing mid-game respawns you as that character.
- [x] Exactly one player node survives a switch.
- [x] The choice replicates, so other players see the right body.
- [x] Direct instantiation still falls back to the menu selection.
- [x] Covered by `tests/smoke_lobby.gd`.

## Out of scope

- A cooldown or restriction on switching mid-fight.

## Verification notes (2026-08-07)

- Live: the client chose Sniper and spawned with 65 hp as seen BY THE
  HOST — previously it would have appeared as a Grabber.
- Regression found while fixing this: removing the CharacterDB read
  from `player._ready` broke every test that instantiates a player
  directly. Resolved with a `-1` sentinel meaning "nobody told us",
  so the direct path still falls back to the menu selection.
