---
xid: EPI-CHARACTER-CHAIN-COLLISION
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-03
bd-id: delve-n4j
shipped: 2026-08-03
---

# Arms & tail collide with the world

## Summary

Make the procedural chains — the Grabber's arms and the Runner's tail —
**collide with all solid geometry** (walls, pillars, the box, enemies),
not just the floor. So they drape over ledges and press against walls
instead of clipping through them.

## Definition of Done

- [x] Arms collide with world geometry, not just the floor.
- [x] The tail collides with world geometry, not just the floor.

## Stories

| #   | Slug            | Size | Notes |
|-----|-----------------|------|-------|
| 011 | world-collision | M    | Ray-check each chain link vs the physics world. |
