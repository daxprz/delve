---
xid: STO-ENEMIES-013
parent: ./epic.md
kind: story
effort: enemies
size: S
status: draft
date: 2026-08-07
depends-on: [STO-ENEMIES-012]
bd-id: delve-g1g
---

# Losing the head is instant death

## Summary

Knock an enemy's head off and it dies immediately — no matter how much
health it had left.

This is the payoff for aiming high. A Sniper's rifle shot or a
full-power tail whip to the head should end a fight outright, even
against an enemy that has barely been scratched. Health stops being
the only thing that matters.

## Definition of Done

- [ ] An enemy whose head comes off dies at once.
- [ ] It dies **even at full health** — this is the whole point, so
      the test must start the enemy undamaged.
- [ ] It leaves a body behind that can still be pushed around
      (STO-ENEMIES-016), rather than vanishing.
- [ ] Proven by a headless test.

## Out of scope

- A special animation or sound for a head shot.

## Depends on

**STO-ENEMIES-012** — a head cannot come off until limbs can come off.
