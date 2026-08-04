---
xid: STO-UI-001
parent: ./epic.md
kind: story
effort: ui
size: S
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-wx2
tasks: 3
complete: 3
---

# ESC opens a pause menu (Resume / Main Menu)

## Summary

While playing, **ESC** opens a pause overlay (dimmed background) with
**Resume** and **Main Menu**. Resume closes it and returns to the game;
Main Menu drops the network and returns to the start (Host/Join +
character select) screen. The game is actually paused underneath.

## Definition of Done

- [x] ESC (while in game) pauses and shows the menu; the mouse frees.
- [x] Resume unpauses, hides the menu, recaptures the mouse.
- [x] Main Menu returns to the start menu (reloads the scene).

## Verification notes (2026-08-03)

- `main.gd`: `_build_pause_menu()` creates a `CanvasLayer` (Resume /
  Main Menu buttons) with `PROCESS_MODE_ALWAYS`; `_unhandled_input`
  toggles it on `ui_cancel` when `_in_game`. `_toggle_pause` sets
  `get_tree().paused` + mouse mode; `_to_main_menu` unpauses, clears the
  multiplayer peer, and reloads the scene. (The player's old ESC
  mouse-toggle was removed so it doesn't conflict.)
- `tests/smoke_pause.gd`: **RESULT: PASS** — the menu has both buttons,
  ESC pauses + shows it, Resume unpauses + hides it.

## Out of scope

- Settings/options in the pause menu; a confirm on Main Menu.
