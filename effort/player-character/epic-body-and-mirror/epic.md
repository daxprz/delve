---
xid: EPI-CHARACTER-BODY-AND-MIRROR
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-03
bd-id: delve-t5z
shipped: 2026-08-03
---

# A real humanoid body + a mirror

## Summary

Give the player a **real jointed humanoid body** (every joint: head,
neck, torso, hips, upper/lower arms, hands, upper/lower legs, feet), and
add a **mirror** in the world so — in this first-person game — the player
can actually see their body, arms, tail and everything.

## Definition of Done

- [x] The player has a jointed humanoid body with all the joints.
- [x] A mirror in the world shows the character's reflection.

## Stories

| #   | Slug          | Size | Notes |
|-----|---------------|------|-------|
| 012 | humanoid-body | L    | Procedural jointed humanoid (20 joints). |
| 013 | mirror        | M    | Reflection camera → SubViewport → glass. |
