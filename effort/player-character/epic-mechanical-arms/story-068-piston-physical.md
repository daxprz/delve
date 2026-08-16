---
xid: STO-CHARACTER-068
parent: ./epic.md
kind: story
effort: character
size: L
status: removed
date: 2026-08-14
depends-on: []
bd-id: delve-z66h
---

# The piston is a real thing that shoots out and retracts

## ⛔ REMOVED from the Grabber (2026-08-16)

The Grabber was remastered into a claw-machine claw
(EPI-CHARACTER-GRABBER-CLAW) and every one of its abilities was taken
out at the operator's request — four abilities, four keys and seven
unfinished piston stories traded for one idea a child can describe in
a sentence.

**This story is kept, not deleted**, the way the Guardian and Builder
were. What it measured and the bugs it found outlive the feature.

## Summary

STO-CHARACTER-067 made the piston an **instant hit**: charge, release,
and whatever was in range got launched. That is a normal attack
wearing a piston's name.

It should be a **physical object**. The two arms visibly lock into one
shaft, and on release the shaft **shoots out** — travelling, hitting
whatever it meets on the way, then **retracting**, with a cooldown
before it can fire again.

**No momentum here.** Unlike the Runner's claws, the piston does not
work out its force from how fast it happens to be moving. A longer
charge fires it further and faster, and what it launches is launched —
simple and predictable.

**And you can stand on it.** The shaft is solid, like any other body
in the world, so a player can get on top of it. A Grabber can raise a
teammate up on the piston, or fire it under someone to lift them.

## What it should look and feel like

- **You can see it.** The two arms combine into one visible shaft.
- **It has a body.** The shaft is collidable — it can hit things
  because it is physically there, not because a check said so. Solid
  enough to **stand on**, like any other body.
- **It launches like the Runner's pounce, but 1.25x faster.** The
  pounce is `POUNCE_FORWARD = 7.5` at full charge, so the piston is
  **9.375**.
- **Any direction.** Straight up, straight down, behind you — it fires
  where you aim, not just forwards.
- **Then it comes back.** It retracts, and there is a cooldown.

## Definition of Done

- [ ] The two arms visibly combine into one shaft in piston mode.
- [ ] The shaft is a real collidable body.
- [ ] Releasing fires it OUT — it travels, rather than hitting
      instantly.
- [ ] A longer charge makes it travel FASTER (not do more damage).
- [ ] Full charge is 1.25x the pounce: 9.375.
- [ ] It fires wherever you aim, including straight up and down.
- [ ] What it hits is launched — a fixed, predictable push, **not**
      worked out from momentum.
- [ ] A player can **stand on the shaft**, and rides it as it moves.
- [ ] It retracts afterwards.
- [ ] There is a cooldown, so it cannot be spammed.
- [ ] Enemies are still ragdolled and players still keep control
      (STO-CHARACTER-067 keeps passing).
- [ ] Proven by a headless test measuring the shaft's speed against
      charge, and its travel.

## Out of scope

- The shaft being destructible or grabbable.

## Notes on standing on it

Worth watching: players currently have **collision exceptions with
each other** (STO-CORE-004), added to stop two players shoving each
other into the sky. The piston must be solid to players WITHOUT
reintroducing that — a platform you can stand on is exactly the shape
of thing that caused the original launch bug, so it needs testing
against the same failure: two people on one piston must not climb
forever.

## Notes

This supersedes how STO-CHARACTER-067 delivers the hit. What that
story decided stays true — enemies ragdoll, players keep control, F
owns the key — but "instant hit in a radius" becomes "a moving object
that connects with what it meets".
