---
xid: STO-CHARACTER-006
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-jbe
tasks: 3
complete: 3
---

# A character-select screen to choose before playing

## Summary

A **character-select screen** in the main menu: a row of buttons (one
per character) with a "Choose your character:" prompt. Clicking a
button picks who you'll spawn as; the choice is highlighted. Then you
press Host to play as that character.

## Definition of Done

- [x] The menu shows a button per character (built from the registry).
- [x] Clicking a character selects it (and highlights it).
- [x] Hosting spawns the player as the selected character.

## Verification notes (2026-08-03)

- `main.gd` `_build_character_select()` adds a "Choose your character:"
  label + an `HBoxContainer` of toggle buttons (`Char0`, `Char1`, …)
  from `CharacterDB.LIST`; pressing one sets `CharacterDB.selected_index`
  and updates the highlight.
- The host's player reads `selected_index` in `_ready`, so Host spawns
  the chosen character.
- `tests/smoke_characters.gd`: **RESULT: PASS** — the select screen has
  a button per character.

## Out of scope

- Scrolling/paging if we ever have many characters (fine for 2).
