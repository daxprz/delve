---
xid: EPI-COMBAT-IMPACT-DAMAGE
parent: ../design.md
kind: epic
effort: combat
status: open
date: 2026-08-14
bd-id: delve-a6v
---

# Things that hit things get hurt

## Summary

Anything moving fast enough hurts what it hits. A crate flung at an
enemy, an enemy slammed into a wall, an enemy swung into *another*
enemy — all of it should knock things down and take health off.

delve already has the physics: real ragdolls, momentum-based hits,
crates you can throw. What is missing is that **impacts between those
things do nothing**. You can hurl a crate straight through an enemy
and it will not even flinch, because damage only ever comes from a
player's own attacks.

This turns the whole world into a weapon: the crate is a weapon, the
enemy you are holding is a weapon, and the wall behind them is a
weapon.

## Definition of Done

- [ ] A thrown or swung object hurts and ragdolls what it hits.
- [ ] Slamming a held enemy into a wall hurts it.
- [ ] Hitting an enemy with another enemy hurts **both**.
- [ ] `E` while holding an enemy crushes the part you hold, with
      damage depending on which part.
- [ ] Damage scales with how hard the impact was, like every other hit
      in delve.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 004 | thrown-objects-hurt | M | the shared impact rule — **the rest build on it** |
| 005 | smash-into-walls | M | a held body vs the world |
| 006 | enemy-vs-enemy | M | a held body vs another body |
| 007 | crush-limb | M | `E` crushes the part you hold |

## Out of scope

- Players being hurt by flying objects. Enemies first; the same rule
  can be pointed at players later.
- Destructible walls.
