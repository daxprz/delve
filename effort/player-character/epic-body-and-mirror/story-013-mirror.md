---
xid: STO-CHARACTER-013
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-8yn
tasks: 3
complete: 3
---

# A mirror to see the character

## Summary

A **mirror** standing in the world near spawn. Because the game is
first-person, the mirror is how you actually see your character — the
body, the mechanical arms, the tail, punch-mode fists, everything. It's
a real planar reflection that tracks your view as you move.

## Definition of Done

- [x] A mirror stands in the world (framed glass).
- [x] It shows a reflection of the scene from the player's viewpoint.
- [x] The reflection updates as the player moves/looks.

## Verification notes (2026-08-03)

- `scripts/mirror.gd` (`Mirror`): a `SubViewport` with a reflection
  `Camera3D` renders onto a glass `QuadMesh` (unshaded, horizontally
  flipped for a mirror image). Each frame the camera is placed at the
  viewer's reflection across the mirror plane and aimed with the
  reflected look/up. The mirror's own frame/glass are on a render layer
  the reflection camera excludes (so it doesn't film itself). Placed by
  `main.gd` in front of the spawn.
- `tests/smoke_mirror.gd`: **RESULT: PASS** — the mirror has a reflection
  camera in a SubViewport + glass, and the camera tracks the viewer
  (moves to the reflected position).

### Change 2026-08-03 — the WHOLE body shows in the mirror

- [x] Operator: the whole body must appear in the mirror. The first fade
      pass made the near body parts transparent, and the mirror shared
      those faded materials, so parts were missing in the reflection.
      Fixed by moving the fade into a **camera-distance shader**
      (STO-CHARACTER-014): the mirror camera is metres away, so the body
      renders **fully solid** in the mirror, while still fading for the
      owner's own close camera.
- `tests/smoke_body_fade.gd` / `smoke_mirror.gd`: **RESULT: PASS**.

## Out of scope

- Perfectly physically-accurate reflections / environment parallax; the
  mirror is tuned to clearly show the player. Mirror in multiplayer
  reflects the local viewer only.
