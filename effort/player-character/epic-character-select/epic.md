---
xid: EPI-CHARACTER-CHARACTER-SELECT
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-03
bd-id: delve-5iy
shipped: 2026-08-03
---

# Choose your character

## Summary

Let the player **choose a character** before playing, and add a **new
second character** so there's a real choice. Characters become data
(a registry) instead of being hardcoded, so more can be added later.

## Definition of Done

- [x] Characters are defined as data (a registry), not hardcoded.
- [x] A new second character exists and plays differently.
- [x] A character-select screen lets the player pick before playing.

## Stories

| #   | Slug                | Size | Notes |
|-----|---------------------|------|-------|
| 004 | character-registry  | M    | Characters as data; player configures from a def. |
| 005 | runner-character    | M    | New "Runner": fast, double-jump, no arms. |
| 006 | select-screen       | M    | Menu buttons to choose your character. |

## Note — multiplayer

Selection currently applies to the **local** player. Other players in
multiplayer still see everyone as the default character; syncing the
chosen character across peers is a future story (kept out of scope so
the existing MP flow and tests stay intact).
