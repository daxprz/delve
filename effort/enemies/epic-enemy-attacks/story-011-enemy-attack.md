---
xid: STO-ENEMIES-011
parent: ./epic.md
kind: story
effort: enemies
size: M
status: draft
date: 2026-08-07
depends-on: []
bd-id: delve-3a2
---

# Enemies attack the player

## Summary

Enemies can now hurt you. Until this landed, `enemy.gd` said so out
loud — *"Enemies only chase — they do not deal damage"* — so delve had
health, healing, a guard and a dodge roll, and nothing had ever needed
any of them.

A swing is deliberately slow and readable: the enemy **stops, rears
back for 0.55 s, and only then lands the blow**. Getting hit should
always be something you could have avoided.

## Definition of Done

- [x] An enemy close enough to a player can hurt it (12 damage).
- [x] There is a wind-up you can see coming — the enemy plants its
      feet and leans back before striking.
- [x] Blocking works against it.
- [x] Dodge-rolling works against it.
- [x] An attack cannot land through a wall.
- [x] Proven by a headless test (9 checks).

## Out of scope

- Ranged or special attacks — melee only.
- Enemies attacking each other.

## Verification notes (2026-08-07)

`tests/smoke_enemy_attack.gd`, 9 checks. Guarding measured at **3.0
damage vs 12.0 unguarded** — exactly the 25% the guard promises — and
a dodge roll takes **none at all**.

### Three things that went wrong on the way

- **The wall check blocked every attack.** Everything in delve sits on
  collision layer 1 — world, players, enemies and ragdoll parts alike
  — so a collision *mask* cannot separate "a wall" from "the very
  player we are aiming at". The ray hit the target and reported it as
  cover. Fixed by excluding both ends and judging by **type**: only a
  `StaticBody3D` counts as a wall.
- **The wall test measured the wrong thing.** It watched the player's
  health, but players regenerate — health went *up* during the wait,
  which would have hidden a hit that did land. It counts landed blows
  now.
- **Testing the guard by holding the guard key did not work**, because
  pressing guard also fires a **parry**, which shoves the enemy out of
  range so it never swings. The blow is measured directly through
  `hurt_by_enemy` instead — the same call a real swing makes.

Teeth checked by disabling the wall rule: **2 blows went straight
through the wall**.

### Multiplayer

Enemy AI runs only on the server, but a player's health lives on the
machine that **owns** that player — health is not a replicated
property. So the server cannot simply damage its own copy of a remote
player: it would drain a health bar nobody is looking at while the
real player felt nothing. `hurt_by_enemy` damages locally if we own
the player, and otherwise sends it to the owner.
