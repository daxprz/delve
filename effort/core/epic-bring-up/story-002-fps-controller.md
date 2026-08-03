---
xid: STO-CORE-002
parent: ./epic.md
kind: story
effort: core
size: S
status: shipped
date: 2026-08-03
depends-on: [STO-CORE-001]
bd-id: delve-lw7
shipped: 2026-08-03
tasks: 4
complete: 4
---

# First-person character controller

## Summary

A first-person player: `scenes/player.tscn` built on
`CharacterBody3D` with a `Camera3D` at head height, driven by
`scripts/player.gd`. WASD movement, mouse look with captured cursor,
jump, gravity. Instanced into `main.tscn` so launching the game drops
you straight into a walkable first-person view.

## Definition of Done

- [x] `scenes/player.tscn`: CharacterBody3D + CollisionShape3D +
      Camera3D (head-height pivot).
- [x] Input map defines `move_forward/back/left/right`, `jump`
      (and Esc releases the mouse).
- [x] WASD moves relative to facing; mouse moves the view (pitch
      clamped ±~89°); Space jumps; gravity applies.
- [x] Player walks on the story-001 ground without falling through or
      jittering.

## Verification notes (2026-08-03)

- `tests/smoke_player.gd` (headless SceneTree test, seed of delve's
  test infra): land / move / jump phases driven by
  `Input.action_press` injection, timed on physics ticks. All PASS:
  rests at y=0.00, moves exactly 5.00 m in 1 s (SPEED=5), jump peak
  1.07 m (matches v²/2g for JUMP_VELOCITY=4.5), re-lands cleanly.
  Exit code is meaningful: 0 pass / 1 fail.
- Rendered boot (Wayland/Vulkan): no script errors.
- Wayland gotcha (reusable): capturing the mouse in `_ready()` errors
  (`pointed_win is null`) before the pointer is over the window.
  Fixed by lazy capture on first mouse event; Esc releases, click
  recaptures. Mouse look itself is not headless-verifiable — code
  inspected, pitch clamped ±89°; confirm feel in manual play.

## Out of scope

- Networked movement/authority (story-003).
- Sprint, crouch, head-bob, footsteps, interaction — later stories.
