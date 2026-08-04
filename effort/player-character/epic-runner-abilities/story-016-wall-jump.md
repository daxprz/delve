---
xid: STO-CHARACTER-016
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-nbt
tasks: 3
complete: 3
---

# Runner wall-jumps (launches off walls) instead of double-jumping

## Summary

The Runner no longer double-jumps. Instead, when it jumps while pressed
against a wall in the air, it **launches off the wall** — pushed away
from the wall and upward. Great for bouncing between walls / up the big
wall.

## Definition of Done

- [x] Jumping while on a wall (and airborne) launches away from the wall
      + upward.
- [x] The launch momentum carries (isn't instantly cancelled by input).
- [x] The Runner no longer has a double jump.

## Verification notes (2026-08-03)

- `characters.gd`: Runner `wall_jump: true`, `double_jump: false`.
- `player.gd`: on jump, if `_wall_jump and is_on_wall()`, sets velocity =
  `wall_normal * WALL_JUMP_PUSH` + up (`_jump * WALL_JUMP_UP`), and a
  short `_wall_lock` window keeps movement input from overriding the
  launch (like the grapple's momentum keep).
- `tests/smoke_walljump.gd`: **RESULT: PASS** — driven into the big
  wall in the air, the Runner launches away (vz 6.7) and up (vy 5.6).

## Out of scope

- Wall-slide (slower fall while on a wall); wall-run.
