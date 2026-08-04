---
xid: EPI-WORLD-PROCEDURAL-MAP
parent: ../design.md
kind: epic
effort: world
status: shipped
date: 2026-08-03
bd-id: delve-y1p
shipped: 2026-08-03
---

# Procedurally generated map

## Summary

Replace the hand-placed buildings (EPI-WORLD-TEST-MAP) with a
**procedurally generated** maze map: random each play, long winding
hallways, compact (not spacious), with **things to climb up**. Kept as
its **own area**, separate from the playground/testing obstacles.

## Definition of Done

- [x] The map is generated procedurally (random layout, seedable).
- [x] Long hallways, compact; climb features to go up.
- [x] It's a separate area from the playground.

## Stories

| #   | Slug    | Size | Notes |
|-----|---------|------|-------|
| 004 | procmap | L    | Randomized-DFS maze + climb platforms, own region. |

## Note

Supersedes the hand-built buildings (STO-WORLD-003) — those scripts were
removed in favour of this generator.
