---
xid: STO-WORLD-002
parent: ./epic.md
kind: story
effort: world
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-5rb
tasks: 3
complete: 3
---

# A wall and pillars to jump around on

## Summary

A **wall** and a row of **pillars at stepped heights** to jump between —
a little parkour course to play on. Built procedurally by the
Playground.

## Definition of Done

- [x] A solid wall exists (a `StaticBody3D` with collision + mesh) the
      player can run into and jump against.
- [x] Several pillars exist (static boxes) the player can stand and
      jump on.
- [x] The pillars are at different (stepped) heights so you can hop up
      from one to the next.

## Verification notes (2026-08-03)

- Built in `scripts/playground.gd`: `_build_wall` (one `StaticBody3D`,
  6 x 3 x 0.4 m) and `_build_pillars` (5 `StaticBody3D` pillars at
  heights 0.6 / 1.2 / 1.8 / 2.4 / 1.4 m, each sitting on the ground,
  spaced 1.9 m apart). Heights are stepped ~0.6 m so each is reachable
  by jumping from the previous one (jump apex ~1 m).
- Headless test `tests/smoke_playground.gd`: **RESULT: PASS** — Wall is
  a StaticBody3D, 5 pillars built, and they are at 5 distinct heights.

### Change 2026-08-03 — bigger wall

- [x] Operator asked for a much bigger wall. Wall grown from 6 × 3 ×
      0.4 m to **24 × 10 × 0.8 m** (sits on the ground, `wall_position`
      raised so its base stays at y=0). A proper climbing/swinging wall.
      `tests/smoke_playground.gd` still **RESULT: PASS**.

## Out of scope

- Moving platforms / fancier parkour — future stories if wanted.
