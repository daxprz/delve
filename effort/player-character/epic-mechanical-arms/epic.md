---
xid: EPI-CHARACTER-MECHANICAL-ARMS
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-03
bd-id: delve-utv
shipped: 2026-08-03
---

# Mechanical grabber arms

## Summary

The player's character has **two big mechanical arms**. The game
**builds the arms itself** (procedurally generated — put together from
parts when the game starts, not hand-placed). The arms are **floppy
physics ragdolls** that hang and **drag behind** the player as they
walk around. When the player clicks a mouse button, the matching hand
**shoots out and grabs** wherever they're aiming: **left mouse button =
left hand**, **right mouse button = right hand**.

This epic delivers that character, built up one playable piece at a
time.

## Definition of Done

- [ ] The player has two mechanical arms that the game generated.
- [ ] The arms ragdoll and drag behind the player as they move.
- [ ] Left-click makes the left hand grab where the player is aiming.
- [ ] Right-click makes the right hand grab where the player is aiming.

## Stories

| #   | Slug             | Size | Notes |
|-----|------------------|------|-------|
| 001 | procedural-arms  | M    | Game builds two arms from segments and attaches them to the player. |
| 002 | ragdoll-drag     | M    | Arms become floppy physics and drag behind as the player walks. |
| 003 | grab-on-aim      | L    | Hand grabs the aim point on click (LMB = left, RMB = right). |

## Decisions

- **Aim = center-screen crosshair.** (Confirmed by operator 2026-08-03,
  option A.) In first-person the mouse controls looking, so "wherever
  the mouse is pointing" means the spot in the **center of the screen**;
  grabbing (story 003) targets that spot via a ray from the camera.
- **Scope confirmed** by operator 2026-08-03: the three stories below
  match the intended character.
