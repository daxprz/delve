---
xid: STO-CHARACTER-068
parent: ./epic.md
kind: story
effort: character
size: L
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-z66h
---

# The piston is a real thing that shoots out and retracts

## Summary

STO-CHARACTER-067 made the piston an **instant hit**: charge, release,
and whatever was in range got launched. That is a normal attack
wearing a piston's name.

It should be a **physical object**. The two arms visibly lock into one
shaft, and on release the shaft **shoots out** — travelling, hitting
whatever it meets on the way, then **retracting**, with a cooldown
before it can fire again.

**The charge sets its SPEED, not its damage.** Hold it longer and the
shaft fires out faster. Everything after that is momentum: what it
hits and how hard is decided by how fast it is actually travelling
when it connects — the same rule as the Runner's claws.

## What it should look and feel like

- **You can see it.** The two arms combine into one visible shaft.
- **It has a body.** The shaft is collidable — it can hit things
  because it is physically there, not because a check said so.
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
- [ ] What it hits is launched by the shaft's MOMENTUM at the moment
      of contact.
- [ ] It retracts afterwards.
- [ ] There is a cooldown, so it cannot be spammed.
- [ ] Enemies are still ragdolled and players still keep control
      (STO-CHARACTER-067 keeps passing).
- [ ] Proven by a headless test measuring the shaft's speed against
      charge, and its travel.

## Out of scope

- The shaft being destructible or grabbable.
- Riding your own piston.

## Notes

This supersedes how STO-CHARACTER-067 delivers the hit. What that
story decided stays true — enemies ragdoll, players keep control, F
owns the key — but "instant hit in a radius" becomes "a moving object
that connects with what it meets".
