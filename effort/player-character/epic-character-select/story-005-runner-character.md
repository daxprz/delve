---
xid: STO-CHARACTER-005
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-ere
tasks: 3
complete: 3
---

# A new second character: the Runner (fast, double-jump, no arms)

## Summary

A **new second character, the Runner** — a fast parkour character that
plays differently from the Grabber: **no mechanical arms**, but **faster
movement** and a **mid-air double jump**. Gives a real choice between
"grappler" and "speedster".

## Definition of Done

- [x] "Runner" exists in the registry with no arms.
- [x] Runner moves faster than the Grabber.
- [x] Runner can double-jump (a second jump in the air).

## Verification notes (2026-08-03)

- Runner def: `speed` 8 (vs Grabber 5), `jump` 5.5, `arms` false,
  `double_jump` true.
- Double jump added in `player.gd` (`_jumps_used`, reset on floor;
  allows a second jump when `_double_jump`).
- `tests/smoke_characters.gd`: **RESULT: PASS** — Runner spawns with NO
  arms and is faster than the Grabber (8.0 > 5.0).

## Out of scope

- A visible third-person body model (players are first-person; the
  arms are the visible difference).
