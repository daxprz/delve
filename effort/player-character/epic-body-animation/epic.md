---
xid: EPI-CHARACTER-BODY-ANIMATION
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-03
bd-id: delve-0qp
shipped: 2026-08-03
---

# Procedural body animation

## Summary

Animate the humanoid body **procedurally** (no keyframed animations) —
legs and arms swing based on how fast the player moves, with an idle
sway when standing.

## Definition of Done

- [x] The body's legs swing when walking (procedural).
- [x] Arms swing opposite the legs; there's an idle sway + bob.

## Stories

| #   | Slug      | Size | Notes |
|-----|-----------|------|-------|
| 015 | walk-anim | M    | Walk phase drives leg/arm swing + bob, from movement speed. |
