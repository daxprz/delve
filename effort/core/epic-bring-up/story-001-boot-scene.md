---
xid: STO-CORE-001
parent: ./epic.md
kind: story
effort: core
size: S
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-1ja
shipped: 2026-08-03
tasks: 4
complete: 4
---

# Boot to a minimal 3D scene

## Summary

A `Main` scene the project boots into: a simple 3D level with a flat
ground plane, directional light, and a `WorldEnvironment` (sky +
ambient light). Sets the project's main scene so `godot --path .`
launches straight into it. This is the stage every later story plays
on.

## Definition of Done

- [x] `scenes/main.tscn` exists with ground (StaticBody3D +
      CollisionShape3D), a DirectionalLight3D, and a WorldEnvironment.
- [x] `project.godot` sets `run/main_scene` to it.
- [x] Launching the project shows the scene with no errors or script
      warnings in stdout.
- [x] Ground is large enough to walk around on (~40×40 m) and has
      collision.

## Verification notes (2026-08-03)

- Headless boot (`godot --headless --quit-after 60`): exit 0, zero
  errors/warnings.
- Rendered boot (Wayland, Vulkan 1.4, Forward+, RTX 4080): scene ran
  and quit cleanly. Only exit-time leaks are engine-internal
  `DisplayServer`/`NativeMenu` (known Wayland teardown noise, not
  scene objects — confirmed via `--verbose`).
- Scene includes a `SpawnPoint` Marker3D at (0, 1, 0) and a
  placeholder static `Camera3D` (story-002's player camera replaces
  it).

## Out of scope

- Player character (story-002).
- Any procedural generation, props, or art beyond primitive meshes.
