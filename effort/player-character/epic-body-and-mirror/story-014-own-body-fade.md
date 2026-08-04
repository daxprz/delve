---
xid: STO-CHARACTER-014
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-rvh
tasks: 3
complete: 3
---

# The owner's body fades out near their camera

## Summary

In first-person, the player's own body parts (chest, shoulders) sit
right in front of the camera and fill the screen. So, **for the owner's
own view only**, each body part **fades out the closer it is to the
camera** — near parts vanish, while farther parts (legs, feet, hands)
stay solid so you can still look down and see them. Other players see
the full solid body.

## Definition of Done

- [x] The owner's own body parts fade based on distance to their camera.
- [x] Near parts (torso) become invisible; far parts (feet) stay solid.
- [x] Only the local player's own body fades (others see it solid).

## Verification notes (2026-08-03)

- `scripts/body.gd`: the owner's body uses a **distance-fade shader** —
  each fragment's alpha is `clamp((distance(fragment, CAMERA_POSITION_WORLD)
  - fade_near) / (fade_far - fade_near))` (`FADE_NEAR` 0.5 → invisible,
  `FADE_FAR` 1.0 → solid). Because it uses the *rendering* camera's
  position, the same body fades for the owner's close camera yet renders
  solid for the mirror's far camera (see the mirror fix, STO-CHARACTER-013).
  This also replaced the old head-layer cull — the head is at ~0 distance
  from the owner's camera, so the shader fades it. Non-owner bodies use a
  plain opaque material.
- `tests/smoke_body_fade.gd`: **RESULT: PASS** — the owner's body carries
  the fade shader with valid near/far params. (Shader output is visual;
  the mechanism is what's asserted.)

## Out of scope

- Smoothing the fade over time (it's instant per-distance) — fine for now.
