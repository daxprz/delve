---
xid: STO-CHARACTER-001
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-g5y
tasks: 9
complete: 9
---

# Two mechanical arms are built by the game and attached to the player

## Summary

When the game starts, it **builds two mechanical arms out of parts**
and attaches one to each side of the player. Nobody places the arms by
hand in the editor — the game generates them from code, so we can
change their shape later.

Each arm is a **jointed chain of 3 parts** connected at mechanical
joints (revised 2026-08-03, operator request):

1. **Upper arm** (higher) — thickest, attaches at the shoulder.
2. **Forearm** (lower) — attaches at the elbow.
3. **Hand** — attaches at the wrist, with a palm and claw digits.

The arms are **big and detailed**: chunky segments, visible joint
spheres at the shoulder/elbow/wrist, and a real hand.

For this first piece the arms can just stick out or hang stiffly —
making them floppy and draggy is the **next** story (002).

## Definition of Done

- [x] On game start, code creates two arms (left and right) from
      segments — no hand-placed arm nodes in the scene.
- [x] Each arm is attached to the correct side of the player and moves
      with the player.
- [x] The number of segments and their length are values we can change
      in one place (so the arms are easy to re-shape later).
- [x] A debug aspect logs that two arms were built and how many
      segments each has.

### Change 2026-08-03 — 3-part jointed anatomy, bigger & detailed

- [x] Each arm is a chain of 3 parts: upper arm → forearm → hand,
      connected at joints (still fully procedural).
- [x] Visible mechanical joints (spheres) at shoulder, elbow, wrist.
- [x] The hand has a palm plus claw digits.
- [x] Arms are noticeably bigger than the first version.

### Change 2026-08-03 — hands are fists

- [x] The hand is now a closed **fist** (a chunky block + 4 knuckle
      ridges) instead of claw digits. Verified by `tests/smoke_arms.gd`
      (asserts a `Fist` block + knuckles and that no `Digit` nodes
      remain). **RESULT: PASS.**

## Verification notes (2026-08-03)

- Built in `scripts/mechanical_arms.gd` (`MechanicalArms`, a `Node3D`),
  instantiated from `scripts/player.gd` `_ready()` — fully runtime, no
  arm nodes in `player.tscn`.
- All shape values are `@export` vars in one place: `segment_count`,
  `segment_length`, `segment_thickness`, `shoulder_offset`,
  `droop_degrees`, `splay_degrees`.
- Interim debug output is a `print("[ARMS] …")` line (delve has no
  `DebugOverlay` autoload yet — that's the target infra; migrate the
  log to a real aspect when it lands).
- Headless smoke test `tests/smoke_arms.gd`: **RESULT: PASS** — game
  built ArmLeft + ArmRight, and asserted `player.tscn` has no
  hand-placed `MechanicalArms` node.

### Change 2026-08-03 — attach at the body's shoulders (not floating)

- [x] Once the humanoid body existed, the mechanical arms looked like
      they floated out at the sides. Moved the arm shoulder anchor
      (`shoulder_offset` → `(0.28, 1.4, 0)`) to line up with the body's
      shoulder joints, and the Grabber's body builds **no human arms** —
      the mechanical arms are its arms. `tests/smoke_body_anim.gd`
      confirms the Grabber has shoulders + mechanical arms and no human
      arms. **RESULT: PASS.**

### Re-verification 2026-08-03 (3-part anatomy)

- Rebuilt as an articulated chain per arm:
  `ArmX/UpperArm/Forearm/Hand`, parts parented in a real kinematic
  chain (ready for ragdoll/IK in story 002/003).
- Detail: a joint sphere at shoulder/elbow/wrist, and a hand with a
  palm + 3 claw digits (two-tone materials: metal limbs, dark joints,
  brass claws). Bigger dimensions + an `arm_scale` multiplier.
- `tests/smoke_arms.gd` updated and re-run: **RESULT: PASS** — both
  arms are 3-part jointed chains, every part has a Joint, each hand has
  a palm + 3 digits.

## Out of scope

- Ragdoll / floppy physics and dragging (story 002).
- Grabbing (story 003).
