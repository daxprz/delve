---
xid: EPI-CORE-BRING-UP
parent: ../design.md
kind: epic
effort: core
status: shipped
date: 2026-08-03
bd-id: delve-49c
shipped: 2026-08-07
---

# Bring-up: minimal playable 3D first-person multiplayer

## Summary

Delivers the first playable build of delve: launch the game into a
simple 3D level, walk around it in first person, and connect two
instances over localhost so each player sees the other move. Scoped
directly from [DES-CORE-001](../design.md) — deliberately minimal, no
roguelike systems, no combat, no polish. Everything later builds on
this running foundation.

## Definition of Done

- [x] Running the project opens a 3D scene with ground, lighting, and
      environment — no script errors in the console.
- [x] Player can move with WASD, look with the mouse (captured
      cursor), and jump; cannot fall through the floor.
- [x] One instance can host and a second instance can join over
      localhost; both players appear in each other's world and
      movement replicates in real time.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 001 | boot-scene | S | Minimal 3D level scene the game boots into |
| 002 | fps-controller | S | First-person CharacterBody3D: WASD + mouse look + jump |
| 003 | basic-multiplayer | M | ENet host/join over localhost, player spawn + movement sync |
