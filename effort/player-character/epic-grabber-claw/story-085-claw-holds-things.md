---
xid: STO-CHARACTER-085
parent: ./epic.md
kind: story
effort: character
size: L
status: draft
date: 2026-08-16
depends-on: []
bd-id: delve-6rht
---

# A shut claw holds what it closed on

## Summary

Shut a claw on something and it **comes with you**. Open it and the
thing drops.

## The unreliability is a feature

Everybody who has used a claw machine knows the feeling: it closes, it
lifts, and halfway back the thing slips out. That is not a bug to be
engineered away — it is the character of the machine, and it is funnier
and more interesting than a grabber that never fails.

So: a claw holds what it has a decent grip on, and a heavy or awkward
thing can work loose. Worth deciding deliberately rather than letting
the physics decide by accident.

delve already has most of the machinery — a hand that grabs where you
aim, fingers that wrap around what they hold, and a held thing carried
out in front (STO-CHARACTER-003, 059, 054). This is those parts, driven
by the claw instead of by the mouse.

## Definition of Done

- [ ] Shutting a claw on something picks it up.
- [ ] Opening drops it, and it behaves normally afterwards.
- [ ] What is held travels with you.
- [ ] Each claw holds its own thing, so two things can be carried.
- [ ] Whether a grip can slip is decided deliberately and written down.
- [ ] Proven by a headless test that grabs, carries and releases,
      measuring the object at each step.

## Out of scope

- Throwing. That was removed with the rest.
- Grabbing players.
- Grabbing the spider.
