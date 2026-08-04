---
xid: STO-CHARACTER-003
parent: ./epic.md
kind: story
effort: character
size: L
status: shipped
date: 2026-08-03
depends-on: [STO-CHARACTER-002]
bd-id: delve-96c
tasks: 5
complete: 5
---

# A hand grabs where you aim (LMB = left hand, RMB = right hand)

## Summary

When the player **clicks a mouse button, the matching hand shoots out
and grabs** whatever they're aiming at:

- **Left mouse button → the LEFT hand grabs.**
- **Right mouse button → the RIGHT hand grabs.**

The hand flies to the aim point, sticks there, and the arm stays
connected — so the player can hang from it, pull, or swing. **Letting
go of the button releases the hand** and the arm goes back to being a
floppy ragdrag (from story 002).

## Definition of Done

- [x] Holding **left-click** sends the left hand to the aim point and
      it grabs on; releasing left-click lets go.
- [x] Holding **right-click** sends the right hand to the aim point and
      it grabs on; releasing right-click lets go.
- [x] The hand only grabs solid things it can reach (out of range or
      empty air = no grab).
- [x] While grabbed, the arm stays attached and pulls on the player
      (you can feel it — hang / swing / pull).
- [x] Both hands can grab at the same time (one per button).
- [~] A debug aspect draws the aim ray and the grab point — deferred to
      the future `DebugOverlay` autoload (not yet in delve).

## Verification notes (2026-08-03)

- `_update_grab_input` in `scripts/mechanical_arms.gd`: edge-triggered
  per hand — LMB drives the left hand, RMB the right. On press it casts
  a ray from the camera through the **center-screen crosshair** (aim
  option A) up to `GRAB_REACH` (7 m); a hit within reach pins that
  hand's fingertip to the point (Verlet target). Release lets go.
- Out-of-range / empty-air aim returns no hit, so no grab.
- While grabbed, `_apply_grab_pull` tugs the player toward the grab
  point via `Player.external_pull` (grapple feel).
- Headless test `tests/smoke_grab.gd`: **RESULT: PASS** — grab engages,
  the grabbed hand reaches the target (0.00 m), the player is pulled
  toward it (1.82 → 1.45 m), and release lets go.
- Both hands grab independently (one per mouse button).

### Bugfix 2026-08-03 — grapple bounce + can't grab the box

Two bugs reported by the operator:

1. **Grabbing a wall made the player bounce/fly like crazy.** Cause:
   the old pull added a constant velocity toward the point every frame,
   fighting gravity/input and overshooting. Fix: the arm now sets a
   proper **grapple override** on the player (`grapple_velocity` /
   `grapple_active` in `player.gd`) — velocity is reeled toward the
   point, clamped, and drops to zero at `HOLD_DIST` (1.2 m), so the
   player smoothly reels in and **holds still** with no bounce.
   - `tests/smoke_grab.gd` now asserts the player settles (speed 0.00
     m/s) at the grapple. **RESULT: PASS.**
2. **Couldn't grab the box.** Cause: grab only pinned to a fixed point
   in space, so a moving RigidBody slipped off. Fix: when the aim ray
   hits a `RigidBody3D` (the box), the arm **reels that body toward the
   hand** instead of grappling the player, and the visual hand sticks
   to the box.
   - `tests/smoke_grab_box.gd`: **RESULT: PASS** — grabbing the box
     reeled it from 2.71 m to 0.65 m from the hand.

### Change 2026-08-03 — grapple is now a swinging rope (keep momentum)

Operator wanted the grapple to **keep the player's momentum** and let
them **swing**, and to **dangle** when they don't have enough speed —
instead of smoothly gliding to a stop.

- Replaced the reel-to-hold override with a **rope/pendulum
  constraint** (`player.gd` `_apply_rope`): the grab point is a fixed
  anchor, the rope length is fixed at grab time, gravity + the player's
  own momentum swing them, and the rope only cancels **outward**
  velocity — so tangential momentum (the swing) is preserved. A slight
  drag lets weak swings settle to a hang. Gentle `AIR_CONTROL` lets the
  player pump the swing.
- Enough speed => they swing up (and can reach a ledge); too slow =>
  they hang below the anchor and dangle.
- `tests/smoke_grab.gd` rewritten as a pendulum test: **RESULT: PASS** —
  rope holds within its length (2.00 m), the player keeps momentum and
  swings sideways 1.71 m, and hangs below the anchor (dangles).

### Change 2026-08-03 — short grab reach

- [x] Operator wanted grabbing to only work up close. `GRAB_REACH`
      reduced from 7 m to **3 m** (the aim ray only finds a grab within
      3 m; the grapple rope length is also capped there). Grab/box-grab
      tests still **RESULT: PASS**.

## Out of scope

- Special powers on the grab (pulling objects toward you, throwing,
  etc.) — capture those as new stories if wanted later.

## Depends on

- **Aim = center of screen** — CONFIRMED (operator 2026-08-03, option
  A). Grab targets a ray cast from the camera through the center-screen
  crosshair.
