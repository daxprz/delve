---
xid: STO-CHARACTER-027
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-6r3
tasks: 1
complete: 1
---

# Grabber pull: yank an enemy toward you

## Summary

The Grabber presses **F** to **yank** the nearest enemy (or the box) toward
themselves — perfect for dragging a runaway enemy into punching range, or
lining up a throw.

## Definition of Done

- [x] F finds the nearest enemy/`grabbable` within `PULL_RANGE` and applies
      an impulse toward the player.

## Verification notes (2026-08-03)

- `player.gd`: `do_pull()` → `apply_knockback` (enemy) / `apply_central_impulse`
  (box) directed from the target toward the player, with a small upward pop.
- `tests/smoke_abilities.gd`: **PASS** — an enemy 8 m ahead gained +Z velocity
  (moved back toward the player).

## Out of scope

- Pulling yourself toward heavy objects; chain-pulling several at once.
