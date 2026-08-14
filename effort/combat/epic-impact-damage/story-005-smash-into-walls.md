---
xid: STO-COMBAT-005
parent: ./epic.md
kind: story
effort: combat
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-45y
---

# Smashing a held enemy into a wall hurts it

## Summary

Grab an enemy and slam it into a wall, a pillar or the floor, and it
takes damage. The harder you swing, the more it hurts.

The Grabber can already haul a limp body around; right now that body
bounces off walls with no consequence. Smashing it should be one of
the Grabber's best attacks — you are using the world as the weapon.

## Definition of Done

- [ ] A held enemy driven into a wall takes damage.
- [ ] Damage scales with impact speed — a gentle nudge does nothing.
- [ ] It works against walls, pillars and the floor.
- [ ] Repeated slams keep hurting (it is not a one-off).
- [ ] It cannot be farmed by holding a body against a wall — contact
      alone is not damage, only **impact** is.
- [ ] Proven by a headless test.

## Depends on

**STO-COMBAT-004** — uses the same impact rule.
