---
xid: STO-ENEMIES-012
parent: ./epic.md
kind: story
effort: enemies
size: M
status: draft
date: 2026-08-07
depends-on: []
bd-id: delve-yow
---

# Limbs can be torn off

## Summary

Hit an enemy hard enough and the part you hit comes off, drops to the
floor as a real physics object, and stays there.

This is the **foundation** of the whole limb epic. Head-kills, leg
limps and weakened arms are all just *consequences* of a limb being
gone — none of them can be built until a limb can actually come off.

The good news is that the hard part is already done. When an enemy
ragdolls, `ragdoll.gd` builds 11 separate rigid bodies joined together
with cone-twist joints. Taking a limb off is mostly a matter of
**breaking the joint** that holds it on, and letting the part carry on
as its own loose object.

## Definition of Done

- [ ] A hard enough hit on a limb detaches it.
- [ ] A weak hit does **not** — limbs must not fall off from a nudge.
- [ ] The detached part falls, lands, and can be pushed around like
      any other physics object.
- [ ] The enemy's remaining body stays stable and does not spaz out
      where the limb used to be (delve has been bitten by joint
      instability before — see STO-ENEMIES-010).
- [ ] The enemy remembers which limbs it has lost, so the other
      stories can ask.
- [ ] Every peer sees the same limb come off in multiplayer — not
      just the player who landed the hit.
- [ ] A headless test proves detachment happens above the threshold
      and does not below it.

## Out of scope

- What losing a limb *does* — that is stories 013, 014 and 015.
- Blood, gore, or stumps.
- Limbs coming off a standing enemy that has not ragdolled (decide
  when we get there — start with ragdolled bodies).

## Open questions

- How hard is "hard enough"? Start from the existing ragdoll
  threshold and tune by feel with the operator.
