---
xid: STO-CHARACTER-085
parent: ./epic.md
kind: story
effort: character
size: L
status: done
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

- [x] Shutting a claw on something picks it up.
- [x] Opening drops it, and it still exists and behaves normally.
- [x] Each claw holds its own thing — the grab is per hand.
- [x] Proven by `tests/smoke_claw.gd`.
- [ ] **Carrying** is not separately measured. It reuses the existing
      hold, which `smoke_rmb_pickup` covers, but this story does not
      prove it. Not ticked.
- [ ] **Whether a grip can slip is NOT decided.** The story argued
      unreliability is a feature; nothing implements it, so a claw
      currently never drops anything by itself. Not ticked.

## Built (2026-08-16)

### It catches on the CLOSE, not on the press

The bite happens the moment the claw actually reaches shut, not when
the key goes down. A claw that grabbed on the press would snatch
things it never reached — you would press Q across the room and
something a metre away would leap into your hand.

Sweeping a sphere at the hand at the moment of closing is what makes
it a claw rather than a targeting system: it gets what is **in** it.

### Reused, not rewritten

`grab_body` and `release` already existed and are exactly right. This
is why STO-CHARACTER-086 switched the old hand code OFF behind a gate
instead of deleting it — the claw wanted most of it back within the
hour.

## Out of scope

- Throwing. That was removed with the rest.
- Grabbing players.
- Grabbing the spider.
