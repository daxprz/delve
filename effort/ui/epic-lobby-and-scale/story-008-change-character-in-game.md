---
xid: STO-UI-008
parent: ./epic.md
kind: story
effort: ui
size: M
status: done
date: 2026-08-15
depends-on: []
bd-id: delve-yexh
---

# Change character while playing, from the pause menu

## Summary

> "change the character in-game" — operator, 2026-08-15

Press ESC while playing, pick a different character, carry on as it.
No going back to the menu, no reconnecting.

## ⚠️ This was already marked done, and is not

STO-UI-005 is `status: shipped` and says the picker appears in "the
main menu, the lobby **and the pause menu**". It appears in the first
two. `_build_character_row` is called from the main menu and the lobby
and **nowhere else** — the pause menu has Resume, a UI-scale row and
Main Menu, full stop.

So the feature was described, believed, and never wired up.

That matters more than the missing button. A story marked shipped that
is not shipped means the record cannot be trusted, and the record is
the thing this project runs on. This is the second time an audit has
turned one of these up — the dash, the momentum claws and the giant
spider are all built but never ticked, which is the same disease in the
other direction.

## Definition of Done

- [x] The character picker is in the pause menu — one button per
      character, **5** of them.
- [x] Choosing a different one respawns you as it, mid-game. Measured:
      **grabber → runner**.
- [x] Everyone else sees the change: the choice travels with the spawn
      (`_spawn_player` reads it), which already worked.
- [x] Proven by `tests/smoke_pause_lobby.gd`, which presses a button
      and then asks the PLAYER who it is — not "does a row exist".
- [x] STO-UI-005 corrected to in-progress with the discrepancy written
      into it.
- [ ] Health and position across the switch are not specified or
      tested. You respawn fresh at your spawn point. Not ticked.

## Built (2026-08-16) — nine lines

The mechanism was all there. `_choose_character` already respawns you
when a round is running, and `_build_character_row` already builds the
picker. The pause menu simply never called it.

That is the whole reason the story was believable enough to be marked
shipped: everything around it was real.

**The test caught a bug that was mine, not the feature's.** Switching
renames the old body to `"1Old"` and frees it next frame, and the first
version of the test grabbed the first child that was not obviously
dead — so it read the body being thrown away and reported that
switching did nothing. It asks for the live node by exact name now.

## Out of scope

- Keeping your health or abilities across the switch.
- Switching during being taken by the spider. That is a state with
  rules of its own.
