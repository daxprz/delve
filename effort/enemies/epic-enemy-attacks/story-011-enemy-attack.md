---
xid: STO-ENEMIES-011
parent: ./epic.md
kind: story
effort: enemies
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-3a2
shipped: 2026-08-07
tasks: 6
complete: 6
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
- [x] Blocking works against it. *(No longer reachable by a player —
      STO-CHARACTER-056 made C a dead key. The measurement below was
      true when taken.)*
- [x] Dodge-rolling works against it. *(Same — see below.)*
- [x] An attack cannot land through a wall.
- [x] Proven by a headless test (9 checks).

## Out of scope

- Ranged or special attacks — melee only.
- Enemies attacking each other.

## Verification notes (2026-08-07)

`tests/smoke_enemy_attack.gd`. Guarding measured at **3.0 damage vs
12.0 unguarded** — exactly the 25% the guard promises — and a dodge
roll took **none at all**.

> **Both are now unreachable.** STO-CHARACTER-056 made **C** a dead
> key at the operator's request, removing block, parry and dodge-roll
> together. The code still exists, unhooked. So delve now has enemies
> that attack and **no defence but footwork** — stepping out of range
> during the 0.55 s wind-up. That telegraph carries the whole weight
> of the fight being fair, which makes it the first thing to revisit
> if fights feel cheap. The test's final phase asserts the new truth:
> a blow costs full damage even with C held.

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

### It broke the pounce, in a way worth remembering

The full suite turned up one regression: `smoke_pounce_cooldown`
failed — a pounce that connected no longer refunded its cooldown.

The cause was not in the attack code at all. Enemies now **stop** to
wind up, so for the first time you can land *on top of* one instead of
crashing into it. And `_nearest_enemy` measured origin-to-origin —
from the player's middle to the enemy's **feet** — while an enemy
capsule is 1.6 m tall. Perched on its head read as **1.60 m away**
against a 1.5 m pounce reach. It missed by ten centimetres.

The measurement was always wrong; enemies simply never used to stand
still long enough for any height to exist between you. Fixed by
measuring to the enemy's centre.

Found only because the whole suite runs, not just the new tests. The
probe that settled it printed distance and height every few ticks —
`dist=1.60 dy=1.59` said "this is entirely vertical" at a glance,
which no amount of reading the pounce code would have.

### A test this broke shipped before it was noticed

`smoke_health` asserted the OPPOSITE of this story — *"an enemy
touching the player does NO damage"* — because that was the truth
until now. It should have been inverted as part of this work.

It was not, because it is one of the tests that must host a game, and
the operator had delve open on port 7777 while this shipped. It never
ran. **v0.1.9 was tagged with it failing**, and nobody knew until the
port freed up.

Inverted now, and the wait was longer than it needed to be: the old
test allowed 40 physics ticks for contact, which is less than a single
0.55 s wind-up. Raised to 200.

The suite runner reporting "skipped (port in use)" separately from
"passed" is the only reason this was recoverable rather than
invisible. **A test that did not run is not a test that passed** —
see STO-TOOLS-009.

### Multiplayer

Enemy AI runs only on the server, but a player's health lives on the
machine that **owns** that player — health is not a replicated
property. So the server cannot simply damage its own copy of a remote
player: it would drain a health bar nobody is looking at while the
real player felt nothing. `hurt_by_enemy` damages locally if we own
the player, and otherwise sends it to the owner.
