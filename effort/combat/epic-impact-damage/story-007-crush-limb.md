---
xid: STO-COMBAT-007
parent: ./epic.md
kind: story
effort: combat
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-aah
---

# E crushes the body part you are holding

## Summary

While holding an enemy, press **E** and the Grabber crushes the exact
body part it has hold of. The enemy takes damage, and **how much
depends on which part you were holding**.

Grab an arm and crush it and you have hurt them a bit. Get hold of the
**head** and crushing it should be devastating.

This makes *where* you grab matter, in the same way STO-ENEMIES-013
made where you aim matter — a head shot ends a fight, and so should a
crushed skull.

## Definition of Done

- [ ] `E` while holding an enemy crushes the held part.
- [ ] Damage depends on the part: head worst, arms least.
- [ ] Crushing the head is lethal or close to it.
- [ ] The crushed limb comes off (EPI-ENEMIES-ENEMY-LIMBS) rather
      than just vanishing health.
- [ ] It cannot be spammed on the same part for free damage.
- [ ] `E` still switches to punch mode when NOT holding an enemy.
- [ ] Proven by a headless test comparing damage per body part.

## Out of scope

- A crush animation. The limb coming off is the feedback.

## Notes

`E` currently toggles punch mode, so this overloads it: holding an
enemy changes what the key does. Worth watching that it never feels
like the mode toggle "randomly stopped working".

## Depends on

- **STO-ENEMIES-012** — limbs come off.
- **STO-COMBAT-004** — damage scaling.
