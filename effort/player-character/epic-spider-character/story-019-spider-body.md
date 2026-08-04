---
xid: STO-CHARACTER-019
parent: ./epic.md
kind: story
effort: character
size: M
status: abandoned
date: 2026-08-03
depends-on: []
bd-id: delve-y6c
tasks: 3
complete: 3
---

# The Spider has a procedural leggy body

## Summary

The Spider gets a **leggy procedural body** instead of the humanoid one:
a low central body + head + **8 legs** splayed out and down to the
ground, with a gentle scuttle bob when moving. Uses the same
distance-fade shader as the humanoid body (fades near the owner's camera,
solid in the mirror).

## Definition of Done

- [x] A non-humanoid spider body with 8 legs is built for the Spider.
- [x] It fades near the owner's camera (shader) like the humanoid body.
- [x] Legs bob/scuttle a little when moving.

## Verification notes (2026-08-03)

- `scripts/spider.gd` (`SpiderBody`): central body + head + eyes and 8
  two-segment legs (4 per side, angled out + down); a `_process` scuttle
  bobs the legs by movement speed. Same fade shader as `body.gd`. Built
  by `player.gd` when the character def has `humanoid: false`.
- `tests/smoke_spider.gd`: **RESULT: PASS** — the Spider has an 8-leg
  SpiderBody and no humanoid Body.

## Out of scope

- Full leg inverse-kinematics (feet planting/stepping on surfaces) —
  the legs are angled + bob for now, not IK-stepped.
