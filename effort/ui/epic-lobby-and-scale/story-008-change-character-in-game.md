---
xid: STO-UI-008
parent: ./epic.md
kind: story
effort: ui
size: M
status: draft
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

- [ ] The character picker is in the pause menu.
- [ ] Choosing a different one respawns you as it, mid-game.
- [ ] Everyone ELSE sees the change — the choice travels with the
      spawn, not from the local menu.
- [ ] Your health and position behave sensibly on the switch.
- [ ] Proven by a headless test that switches mid-game and checks the
      player really is the new character afterwards.
- [ ] STO-UI-005's claim is corrected, so the record stops lying.

## Out of scope

- Keeping your health or abilities across the switch.
- Switching during being taken by the spider. That is a state with
  rules of its own.
