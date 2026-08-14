---
xid: STO-COMBAT-004
parent: ./epic.md
kind: story
effort: combat
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-3vj
---

# A thrown or swung object hurts what it hits

## Summary

Throw a crate at an enemy and it should hurt them and knock them down.
At the moment it passes through the fight doing nothing at all.

This story also builds the **shared impact rule** the rest of the epic
uses: how fast does something have to be moving to count, and how much
damage does a given impact do? Everything else here — walls, bodies,
crushing — is that same rule pointed at different things.

Damage comes from **momentum**, like every other hit in delve
(`dv = impulse / mass`): a heavy crate at walking pace and a light one
flung hard should feel different.

## Definition of Done

- [ ] A crate moving fast enough hurts an enemy it hits.
- [ ] A slow or resting crate does **nothing** — you cannot kill
      anything by leaning a box against it.
- [ ] A hard enough hit ragdolls the enemy.
- [ ] Damage scales with impact speed and the object's mass.
- [ ] It works for a thrown crate AND one swung while held.
- [ ] An enemy cannot be hurt twice by the same impact.
- [ ] Proven by a headless test measuring health against impact speed.

## Out of scope

- Objects damaging each other, or the player.
