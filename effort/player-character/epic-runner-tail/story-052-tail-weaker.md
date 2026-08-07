---
xid: STO-CHARACTER-052
parent: ./epic.md
kind: story
effort: character
size: S
status: draft
date: 2026-08-07
depends-on: []
bd-id: delve-40d
---

# The tail whip hits softer

## Summary

The Runner's tail does too much damage. Turn it down.

An enemy has 60 health. The tail currently deals swing speed x 0.9,
capped at 40 — so **two** decent whips kill anything in the game, and
a fast one nearly does it alone. That leaves no reason to use anything
else the Runner has, and no fight lasts long enough to be interesting.

This is a **balance change, not a feature**: one number, chosen by
playing.

## Definition of Done

- [ ] The tail deals noticeably less damage than it does now.
- [ ] It still trips and ragdolls enemies exactly as it does today —
      only the *damage* changes, not the physics.
- [ ] `tests/smoke_tail_damage.gd` is updated to the new number and
      still passes.
- [ ] The operator plays it and agrees it feels right. This one cannot
      be settled by a test — only by how it feels.

## Out of scope

- Changing the tail's reach, speed, or trip behaviour.

## Notes

Small enough to really be a TASK rather than a story — it is one
number. It gets its own story only because it does not belong inside
any of the others.
