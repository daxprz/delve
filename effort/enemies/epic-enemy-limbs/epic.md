---
xid: EPI-ENEMIES-ENEMY-LIMBS
parent: ../design.md
kind: epic
effort: enemies
status: shipped
date: 2026-08-07
bd-id: delve-r2t
shipped: 2026-08-07
---

# Enemies can lose limbs

## Summary

Hit an enemy hard enough in the right place and the part comes off —
and **what** you took off changes what it can still do to you. Take a
leg and it limps. Take both and it is finished. Take an arm and its
hits get weaker; take both and it cannot hurt you at all. Take the
head and it drops on the spot.

This turns fighting into something you can *aim*. Right now every hit
is the same hit — you just wear the enemy's health down. Once limbs
come off, a Runner's tail sweep at knee height and a Sniper's shot to
the head are different tactics with different results.

It builds on something delve already has: the ragdoll is made of 11
separate physics parts (Head, UpperArmL/R, ForearmL/R, ThighL/R,
ShinL/R), each already its own body with its own mass. The pieces that
need to come off already exist — nothing has to be re-modelled.

## Definition of Done

- [x] A limb can be knocked off an enemy and falls as a real physics
      object.
- [x] Losing the head kills instantly.
- [x] Losing one leg slows it down (to 40%); losing both kills it.
- [x] Losing one arm weakens its attack (12.0 -> 4.2); losing both
      means it cannot damage you at all.
- [x] Every rule above is proven by a headless test, not by eye.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 012 | limbs-come-off | M | the mechanic — **everything else waits on this** |
| 013 | head-instant-kill | S | head off = dead |
| 014 | leg-loss | S | one leg slower, two legs dead |
| 015 | arm-loss | S | needed STO-ENEMIES-011 first |

## Out of scope

- Blood or gore effects.
- Limbs growing back, or enemies healing.
- Players losing limbs — this epic is about enemies only.
