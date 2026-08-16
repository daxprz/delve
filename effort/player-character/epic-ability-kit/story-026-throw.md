---
xid: STO-CHARACTER-026
parent: ./epic.md
kind: story
effort: character
size: M
status: removed
date: 2026-08-03
depends-on: []
bd-id: delve-6ck
tasks: 2
complete: 2
---

# Grabber throw: grab a box/enemy and hurl it

## ⛔ REMOVED from the Grabber (2026-08-16)

The Grabber was remastered into a claw-machine claw
(EPI-CHARACTER-GRABBER-CLAW) and every one of its abilities was taken
out at the operator's request — four abilities, four keys and seven
unfinished piston stories traded for one idea a child can describe in
a sentence.

**This story is kept, not deleted**, the way the Guardian and Builder
were. What it measured and the bugs it found outlive the feature.

## Summary

The Grabber presses **G** to grab a nearby **enemy or the movable box** and
hold it floating in front; pressing **G** again **hurls it forward**. A
thrown enemy flies and takes fall damage when it lands — reuses the carry,
knockback, and fall-damage systems.

## Definition of Done

- [x] First G grabs the nearest enemy (or a `grabbable` box) in reach and
      holds it in front of the player.
- [x] Second G throws it forward with `THROW_FORCE` (enemy → knockback +
      fall damage; box → physics impulse).

## Verification notes (2026-08-03)

- `player.gd`: `do_throw()` toggles grab/release; `_grab_throwable` prefers an
  enemy then a `grabbable` RigidBody; `_carry_held` floats it in front;
  `_release_throw` applies the forward impulse. The box is tagged
  `grabbable` in `playground.gd`.
- `tests/smoke_abilities.gd`: **PASS** — grabbed an enemy, then hurled it
  forward at vz≈-22.

## Out of scope

- Aiming/charging the throw; throwing teammates; catching.
