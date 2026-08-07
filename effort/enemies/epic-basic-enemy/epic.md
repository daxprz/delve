---
xid: EPI-ENEMIES-BASIC-ENEMY
parent: ../design.md
kind: epic
effort: enemies
status: shipped
date: 2026-08-03
bd-id: delve-zeu
shipped: 2026-08-06
---

# A basic follower enemy

## Summary

A first, deliberately-simple enemy: it **walks toward the player**.
Something to give the world life (and to punch). Kept minimal on
purpose — no attacks or health yet.

## Definition of Done

- [x] Enemies spawn in the world.
- [x] An enemy walks toward the nearest player.
- [x] Enemies can be knocked back by the Grabber's punch / shockwave.

## Stories

| #   | Slug     | Size | Notes |
|-----|----------|------|-------|
| 001 | follower | M    | CharacterBody3D that chases the nearest player. |
