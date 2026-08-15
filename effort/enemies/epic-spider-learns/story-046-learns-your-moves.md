---
xid: STO-ENEMIES-046
parent: ./epic.md
kind: story
effort: enemies
size: M
status: in-progress
date: 2026-08-14
depends-on: []
bd-id: delve-uhw3
---

# It learns how you play

## Summary

It **watches you** and learns four things, all of which the operator
asked for by name:

| It learns | So it can |
|---|---|
| **Which way you run** | stop chasing and start cutting you off |
| **When you dodge and block** | wait your dodge out, or make you spend it early |
| **Where you hide** | check your favourite places first |
| **Which character you play** | plan differently for a Runner than a Grabber |

None of this is told to it. All of it comes from watching what you
actually do, and it keeps counting for as long as you keep playing.

## Definition of Done

- [x] It records which way you break — **across its own line of sight**,
      the only frame in which "they always go left" means anything.
- [x] It aims where you are GOING: a spider that watched you aims
      **1.51 m ahead**; one that watched nobody aims **0.00 m** off,
      straight at you, exactly as before.
- [x] It records the places you spend time and names your favourite.
- [x] It records which character you play.
- [x] Everything comes from watching. The test asserts it does NOT know
      the character of someone it only saw as a bare node.
- [x] Compared against a spider that watched nobody, every time.
- [x] Proven by `tests/smoke_spider_mind.gd`.
- [ ] Your dodge and block timing is **counted but not used**. It knows
      how often you dodge; nothing acts on it yet. Not ticked.

## Out of scope

- Learning from other players' games.
- Learning things it could not possibly see.
