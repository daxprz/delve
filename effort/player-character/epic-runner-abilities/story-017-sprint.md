---
xid: STO-CHARACTER-017
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-fr8
tasks: 2
complete: 2
---

# Runner walks like the Grabber, sprints fast with Shift

## Summary

The Runner now **walks at the same speed as the Grabber** (5), and
**holding Shift sprints** at its old fast speed (8). So it's calm by
default and fast on demand.

## Definition of Done

- [x] Runner walk speed equals the Grabber's.
- [x] Holding Shift makes the Runner move fast (its old speed).

## Verification notes (2026-08-03)

- New input action `sprint` bound to **Shift** (project.godot).
- `characters.gd`: Runner `speed: 5`, `sprint: 8` (Grabber `speed: 5`,
  `sprint: 5`).
- `player.gd`: movement uses `_sprint_speed` while `sprint` is held, else
  `_speed`.
- `tests/smoke_characters.gd`: **RESULT: PASS** — Runner walks the same
  as the Grabber (5.0) and sprints faster (5.0 → 8.0).

## Out of scope

- A stamina bar / sprint limit; sprint FOV change.
