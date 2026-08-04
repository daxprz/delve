---
xid: STO-CHARACTER-012
parent: ./epic.md
kind: story
effort: character
size: L
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-7ml
tasks: 4
complete: 4
---

# The player has a real jointed humanoid body

## Summary

The player gets a **real humanoid body** built procedurally from a joint
at every body part: pelvis, torso, neck, head, and per side a shoulder →
upper arm → forearm → hand and a hip → thigh → shin → foot. It's a proper
skeleton hierarchy (each joint parented to the previous), coloured by the
character. Every character gets one.

## Definition of Done

- [x] A jointed humanoid body is built in code and attached to the player.
- [x] Every joint exists (head, neck, torso, pelvis, upper+lower arms,
      hands, thighs, shins, feet) — 20 joints.
- [x] The joints are a real parented hierarchy.
- [x] The owner's own head/neck don't block their first-person camera
      (but are visible in the mirror).

## Verification notes (2026-08-03)

- `scripts/body.gd` (`Body`): builds the skeleton with `_joint()` +
  `_seg()` helpers; head/neck meshes are on a separate render layer
  (`HEAD_LAYER`) so the owner's camera culls them (`player.gd` clears
  that bit on the authority's camera). Outfit colour comes from the
  character def.
- `tests/smoke_body.gd`: **RESULT: PASS** — Body has 20 joints, all
  named joints present, and the forearm is parented under the upper arm.

### Change 2026-08-03 — plain gray base, no eyes

- [x] The body is now **fully gray** (single gray material for all
      parts) with **no eyes** — a blank, untextured base ready for
      textures to be added later. Character colour is no longer used on
      the body. `tests/smoke_body.gd` still **RESULT: PASS** (20 joints).

## Out of scope

- Animating / posing the body (walk cycles), and ragdolling it — future.
- Texturing the gray base (the reason it's left plain gray).
