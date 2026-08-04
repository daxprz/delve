---
xid: STO-CHARACTER-004
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-3te
tasks: 3
complete: 3
---

# Characters are pickable definitions (not hardcoded)

## Summary

Characters are defined as **data** (a registry) instead of being baked
into the player. Each entry lists name, colour, speed, jump, whether it
has the mechanical arms, and whether it can double-jump. The player
reads its character's def and configures itself from it.

## Definition of Done

- [x] A `scripts/characters.gd` registry lists characters as data with
      a `selected_index`.
- [x] The player configures its speed / jump / arms / double-jump from
      the chosen def in `_ready`.
- [x] Adding a character means adding a data entry — no player-code
      changes needed.

## Verification notes (2026-08-03)

- `scripts/characters.gd`: static `LIST` of def dictionaries + helpers
  `count()` / `get_def(i)` and a static `selected_index`.
- `player.gd` reads `CharacterDB.get_def(character)` and applies
  `_speed` / `_jump` / `_has_arms` / `_double_jump`; the authoritative
  player picks up `CharacterDB.selected_index`.
- `tests/smoke_characters.gd`: **RESULT: PASS** — registry has 2 chars,
  defs have all fields.

## Out of scope

- Syncing the chosen character to other peers in multiplayer.
