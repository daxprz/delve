---
xid: STO-UI-005
parent: ./epic.md
kind: story
effort: ui
size: M
status: in-progress
date: 2026-08-07
depends-on: []
bd-id: delve-d34
shipped: 2026-08-07
tasks: 6
complete: 6
---

# Change character easily, including mid-game

## ⚠️ Correction (2026-08-15): the pause-menu half was never built

This story was marked **shipped** and says the picker appears in the
main menu, the lobby *and the pause menu*. It appears in the first two.
`_build_character_row` is called from the main menu and the lobby and
nowhere else; the pause menu has Resume, a UI-scale row and Main Menu.

So mid-game character switching — the headline of this story — does not
exist. Found when the operator asked for it as a new feature.

Reopened as **in-progress**, and the missing half is
**STO-UI-008**. Corrected rather than quietly re-shipped, because a
story marked done that is not done makes the whole record worthless.

## Summary

Changing character used to mean going back to the main menu. The same
picker appears in the **main menu and the lobby** — and was intended to
appear in the pause menu too, so that choosing a different character
mid-game respawns you as it with no reconnecting. **That last part is
not built** (see the correction above).

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
