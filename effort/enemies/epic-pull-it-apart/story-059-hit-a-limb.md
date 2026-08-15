---
xid: STO-ENEMIES-059
parent: ./epic.md
kind: story
effort: enemies
size: L
status: draft
date: 2026-08-15
depends-on: []
bd-id: delve-kjsb
---

# Hitting a limb hurts it and knocks it aside

## Summary

> "so the player (using the graber as an example) can smack the out of
> the way to do damge"

Hit a limb and two things happen: the limb is **shoved aside**, and the
creature is **hurt**.

The Grabber is the example because it already has the tools — a punch
whose power comes from your momentum (STO-CHARACTER-008) and a piston.
But this should be about the LIMB being struck, not about which
character struck it, so anything that can hit should be able to do it.

## Why hitting a limb should be worth doing

At the moment there is no reason to attack a spider's leg rather than
its body: damage is damage. Give limbs their own consequences and the
fight gets a shape — knock a leg out from under it and it lurches
(STO-ENEMIES-057 already does this); batter the same limb enough and it
comes off (060).

That turns "hit the monster" into "which part of the monster, and
why" — which is the difference between a health bar and a fight.

## Definition of Done

- [ ] Hitting a limb shoves that limb, not the whole creature.
- [ ] It damages the creature.
- [ ] Hitting a limb hard enough also makes it stumble — which already
      works (STO-ENEMIES-057) and must keep working.
- [ ] Repeated hits on the SAME limb accumulate, so a limb can be
      worked on.
- [ ] It works for any attack, not only the Grabber's.
- [ ] Proven by a headless test measuring damage from a limb hit
      against damage from a body hit, so "it hurt it" cannot pass for
      "hitting the limb did anything".

## Out of scope

- The limb coming off. That is 060.
- Limbs having their own health bars on screen.
