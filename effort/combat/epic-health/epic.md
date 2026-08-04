---
xid: EPI-COMBAT-HEALTH
parent: ../design.md
kind: epic
effort: combat
status: shipped
date: 2026-08-03
bd-id: delve-gzo
shipped: 2026-08-03
---

# Health system

## Summary

A health system: each character has max health (the **Grabber is
tougher than the Runner**), a health bar shows it, enemies hurt you on
contact, and dying respawns you.

## Definition of Done

- [x] Per-character health; Grabber > Runner. Health bar shown.
- [x] Enemies damage the player on contact; death respawns at full HP.

## Stories

| #   | Slug          | Size | Notes |
|-----|---------------|------|-------|
| 001 | player-health | M    | `health` per character + a corner health bar. |
| 002 | enemy-damage  | S    | Enemy contact damage + respawn on death. |
