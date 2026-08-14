---
xid: STO-CHARACTER-055
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-13
depends-on: []
bd-id: delve-6dy
shipped: 2026-08-13
tasks: 7
complete: 7
---

# RMB picks things up and holds them out

## Summary

Pressing **RMB** on a loose object picks it **up** and holds it **out
in front** of you, at eye level, where you can see it and aim a throw.
Not dragged into your chest, and not left sitting on the floor.

## This supersedes STO-CHARACTER-053

STO-CHARACTER-053 made a crate grabbed by an arm **stay exactly where
it was** — no force applied at all. That was built to the operator's
explicit instruction and it did what it said.

Having played it, the operator wants the opposite behaviour on RMB:
the thing should be **picked up and held out**. So 053's outcome is
replaced. It is not deleted — the reasoning there is still why a
grabbed crate must never be *reeled into the player*, which remains
true. What changes is where it goes instead: **out in front**, rather
than staying put.

The path this story went down, recorded because it looks like
flip-flopping otherwise and is not:

| | what a grabbed crate did |
|---|---|
| originally | reeled into the shoulder — overshot, bounced, never settled |
| STO-CHARACTER-053 | stayed exactly where it was |
| **this story** | **picked up and held out in front at eye level** |

Each step was the operator's call after playing the previous one. The
one constant across all three: **it must not be dragged into the
player.**

## Definition of Done

- [x] RMB on a loose object picks it up.
- [x] It is held out in front — 2.40 m from the eye, dead centre of
      view.
- [x] Held at eye level (0.00 m off the eye line) and follows the
      look direction up and down.
- [x] Releasing RMB lets go, and the object then falls like anything
      else rather than hanging in the air.
- [x] It is never dragged into the player — 2.88 m away while held.
- [x] Carrying a limp **enemy** uses the same carry point.
- [x] Proven by a headless test measuring the real position
      (10 checks).

## Verification notes (2026-08-13)

`tests/smoke_rmb_pickup.gd`, 10 checks.

`smoke_grab_box.gd` was rewritten to guard the ONE thing that has
survived all three versions of this behaviour — never dragged into the
player — rather than re-asserting whichever variant is current. That
assertion has now outlived two rewrites, which is a fair sign it is
the real requirement and the rest was detail.

## Out of scope

- Changing throw force or range.
- The `G` throw ability, which already picks up and holds out
  (STO-CHARACTER-054). This story gives the arms the same behaviour.
