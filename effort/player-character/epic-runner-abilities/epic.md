---
xid: EPI-CHARACTER-RUNNER-ABILITIES
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-03
bd-id: delve-abb
shipped: 2026-08-03
---

# Runner: wall-jump + sprint

## Summary

Rework the Runner's movement: it **wall-jumps** (launches off walls)
instead of double-jumping, and it now **walks at the same speed as the
Grabber** but **sprints fast (its old speed) while holding Shift**.

## Definition of Done

- [x] Runner launches off a wall when it jumps against one (no more
      double jump).
- [x] Runner walks at the Grabber's speed; Shift sprints faster.

## Stories

| #   | Slug      | Size | Notes |
|-----|-----------|------|-------|
| 016 | wall-jump | M    | Jump against a wall → launch away + up. |
| 017 | sprint    | S    | Walk = 5; Shift sprint = 8. |
