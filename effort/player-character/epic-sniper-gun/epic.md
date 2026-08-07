---
xid: EPI-CHARACTER-SNIPER-GUN
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-07
bd-id: delve-f0q
shipped: 2026-08-07
---

# Sniper: the long-range gun

## Summary

The Sniper's actual play style: a gun that kills from across the map.
Everyone else in delve fights at arm's length — grabbing, punching,
tail-swiping, pouncing — so this is the first weapon that works at
range, and the first reason to want distance instead of closing it.

The Sniper is **blind** (STO-CHARACTER-040): it sees only the echoes
of things that move, and by the operator's own design decision those
echoes outline **the room, never the creature**. So a gun raises a
real question this epic has to answer: how do you aim at something you
cannot see?

## Definition of Done

- [x] The Sniper can fire a shot that reaches across the map.
- [x] A hit does serious damage and knocks the target down.
- [x] Firing is deliberate and punishing to spam (slow, or limited).
- [x] Aiming is possible for a blind character (see open question).
- [x] Other characters are unaffected.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 047 | gunshot | L | The rifle, and the bang that lights the room |
| 048 | lidar | M | RMB scan that paints ahead and holds |
| 049 | lidar-enemies | S | Enemies on the lidar (absorbed into 051) |
| 050 | echo-memory | L | 5-minute memory, gaussian spread, sound bus |
| 051 | echo-palette | M | Blue room / red enemies / green friends, dots |

## Aiming decision (operator, 2026-08-07)

Asked how a blind Sniper should aim, the operator chose **"the gunshot
lights the room"** — firing is enormously loud and floods the area
with one huge echo wave. You shoot to see. Rejected: a sonar scope, a
target-revealing ping, and softening the never-outline-a-creature
rule. It is the only option that costs you something to use, which is
what makes the Sniper tense rather than simply strong.
