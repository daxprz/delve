---
xid: EPI-WORLD-PLAYGROUND
parent: ../design.md
kind: epic
effort: world
status: shipped
date: 2026-08-03
bd-id: delve-5lc
shipped: 2026-08-03
---

# A playground to move and jump around

## Summary

A little obstacle playground to move and play around in: a **movable
box** the player can push, and a **wall + stepped pillars** to jump
between. Gives the player (and the mechanical arms) things to interact
with.

## Definition of Done

- [x] A box the player can push around the floor.
- [x] A wall and a set of pillars at stepped heights to jump on.

## Stories

| #   | Slug              | Size | Notes |
|-----|-------------------|------|-------|
| 001 | movable-box       | M    | Pushable RigidBody crate (player shoves it). |
| 002 | wall-and-pillars  | M    | Static wall + 5 stepped pillars for parkour. |
