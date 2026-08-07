---
xid: STO-UI-003
parent: ./epic.md
kind: story
effort: ui
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-xlt
shipped: 2026-08-07
tasks: 6
complete: 6
---

# UI scale factor, persisted across restarts

## Summary

A UI size setting (1x to 3x) that is remembered between sessions.
delve's menus were sized on a 1080p Linux screen and are unreadably
small on a high-DPI Mac, and having to fix that on every launch would
be worse than the problem.

A `Settings` autoload keeps it in `user://settings.json` and pushes it
into the window's content scale, which scales all UI and leaves the 3D
view alone. The control appears in the main menu, the lobby AND the
pause menu — if the UI is too small to read, you must be able to fix
it from wherever you are, including mid-game.

## Definition of Done

- [x] UI scale adjustable between 1x and 3x.
- [x] It reaches the window, so the UI actually changes size.
- [x] Absurd values are clamped rather than obeyed.
- [x] The choice survives a restart.
- [x] Adjustable from the menu and mid-game from the pause menu.
- [x] `tests/smoke_ui_scale.gd` passes (9 checks).

## Out of scope

- Per-element font sizing, or a separate HUD scale.

## Verification notes (2026-08-07)

- Persistence proven the honest way: set 2x, wipe the in-memory
  value, reload from disk — the same path a fresh launch takes.
