---
xid: STO-CHARACTER-044
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-cai
shipped: 2026-08-07
tasks: 6
complete: 6
---

# Grabbing ragdolls enemies, holds them, and pulls the Grabber in

## Summary

The Grabber's aim-grab does three things it previously didn't.

**Enemies can be grabbed at all.** Enemies are `CharacterBody3D`, and
the grab only recognised `RigidBody3D`, so aiming at one latched onto
it as if it were scenery. Now grabbing an enemy makes it **go limp
instantly** (a full physics ragdoll) and the arm holds one of its
ragdoll parts, so it is dragged along behind you.

**A held enemy stays limp.** Ragdolls normally get up after ~2 s; a
held one stays down until released, then drops and recovers on its
own.

**The Grabber actually pulls himself.** Grabbing anything solid — a
wall, a pillar, the floor — now reels the player toward the anchor at
up to 12 m/s. Previously a solid grab did nothing but stick a hand to
a point.

## Definition of Done

- [x] Grabbing something solid hauls the player toward it.
- [x] The reel is speed-capped, so it is a haul and not a rocket.
- [x] Grabbing an enemy ragdolls it and holds it.
- [x] A held enemy stays limp until released; a released one recovers.
- [x] Letting go by any route (release, punch-mode switch) frees the
      enemy — it is never left permanently limp.
- [x] `tests/smoke_grabber_grapple.gd` passes headless (12 checks,
      non-hosted).

## Out of scope

- Throwing the held enemy (the separate `do_throw` ability already
  covers hurling).
- Swinging on the anchor like a pendulum — this is a straight reel-in.

## Verification notes (2026-08-07)

- 12/12 PASS: solid grab hauls 6.15 m at the 12 m/s cap; grabbing an
  enemy ragdolls + holds it (arm holds its Torso RigidBody); held
  through 200 ticks without rising; released cleanly and recovered.
- Bug found during the build: the reel was being cancelled by ground
  friction — the walk code damps horizontal velocity every tick, so
  only a single tick of pull survived (0.43 m/s, 0.32 m travelled).
  Grappling now suspends that damping, the same way a wall-jump
  launch and the push-back rebound do. That is three separate
  features that have hit this exact trap.
- Hosting-based arm tests (smoke_grab, smoke_arms, smoke_punch,
  smoke_arm_solid, smoke_grab_box) not run: port 7777 held by the
  operator's play session.
