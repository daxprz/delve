---
xid: STO-CHARACTER-025
parent: ./epic.md
kind: story
effort: character
size: M
status: removed
date: 2026-08-03
depends-on: []
bd-id: delve-683
tasks: 2
complete: 2
---

# Grabber grapple-zip: Q instantly zips to the aimed point

## ⛔ REMOVED from the Grabber (2026-08-16)

The Grabber was remastered into a claw-machine claw
(EPI-CHARACTER-GRABBER-CLAW) and every one of its abilities was taken
out at the operator's request — four abilities, four keys and seven
unfinished piston stories traded for one idea a child can describe in
a sentence.

**This story is kept, not deleted**, the way the Guardian and Builder
were. What it measured and the bugs it found outlive the feature.

## Summary

The Grabber presses **Q** to **instantly zip** toward whatever surface the
camera is aimed at — a fast dash to the point (unlike the grapple *swing*,
which holds you at rope length). Great for closing distance or reaching a
ledge in one move.

## Definition of Done

- [x] Q raycasts from the camera; if it hits within `ZIP_RANGE`, the player
      dashes to that point at `ZIP_SPEED`.
- [x] The zip ends near the point (or on a safety timeout) and hands control
      back with walking-speed momentum.

## Verification notes (2026-08-03)

- `player.gd`: `do_zip()` raycasts (`_aim_ray`), sets `_zip_target`; while
  `_zipping`, `_zip_move` drives `velocity` toward the target and overrides
  normal movement in `_physics_process`. `test_zip(point)` is the headless hook.
- `tests/smoke_abilities.gd`: **PASS** — from z=40 the player zipped to z≈31.

## Out of scope

- Zipping to enemies / mid-air anchors; a cooldown or fuel cost.
