---
xid: DES-CORE-001
kind: design
effort: core
status: shipped
date: 2026-08-03
guidance: ./guidance.md
hugs: []
tenets: []
bd-id: delve-cdc
shipped: 2026-08-03
---

# Core Game Bring-up

## Overview

Get a minimal, playable version of delve running: a 3D first-person
game in Godot 4.6 with basic multiplayer. This design deliberately
scopes to "very basic" — a player can launch the game, walk around a
simple 3D level in first person, and see other connected players
moving. No roguelike systems, no combat, no progression yet.

## Background

delve is a fresh Godot 4.6 (Forward+) project with only the default
engine config committed. Everything downstream — testing
infrastructure, gameplay systems, content — needs a running game to
attach to. This design establishes that foundation.

## Current State

- `project.godot` exists (Godot 4.6, Forward+ renderer, 3D).
- No scenes, no scripts, no autoloads yet.

## Goals

1. Project boots to a minimal 3D scene (ground, light, environment).
2. First-person character controller: WASD movement, mouse look, jump.
3. Basic multiplayer: one instance hosts, another joins over localhost;
   each player sees the others move in real time.

## Non-Goals

- Roguelike systems (procedural levels, character growth, items).
- Combat, UI beyond a bare host/join affordance, art/sound polish.
- Dedicated servers, matchmaking, or internet play (localhost only).

## Approach

Use Godot's built-in high-level multiplayer (`ENetMultiplayerPeer` +
`MultiplayerSpawner`/`MultiplayerSynchronizer`). Keep the scene tree
simple: `Main` scene owning the level and a spawn point; `Player`
scene as a `CharacterBody3D` with a first-person `Camera3D`.
Authority-per-player (each peer drives its own player node).
