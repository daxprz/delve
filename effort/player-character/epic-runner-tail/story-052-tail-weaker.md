---
xid: STO-CHARACTER-052
parent: ./epic.md
kind: story
effort: character
size: S
status: in-progress
date: 2026-08-07
depends-on: []
bd-id: delve-40d
---

# The tail whip hits softer

## Summary

The Runner's tail did too much damage, so it has been turned down.

An enemy has 60 health. The tail dealt swing speed x 0.9 capped at 40
— **two** decent whips killed anything in the game. There was no
reason to use anything else the Runner has, and no fight lasted long
enough to be interesting.

Turned down **twice**:

| | scale / cap | solid hits to kill a 60-health enemy |
|---|---|---|
| originally | 0.9 / 40 | ~2 |
| first pass | 0.35 / 15 | ~4 |
| **now** | **0.23 / 10** | **~6** |

The operator played the 4-hit version and wanted it lower still, so
the tail is now a **control tool**: it trips, sweeps and shoves, and
the damage is a bonus rather than the point.

The scale drops along with the cap so the speed curve keeps its shape
— a swing still has to be about as fast as it always did to hit for
full, instead of every light tap maxing out.

## Definition of Done

- [x] The tail deals noticeably less damage (cap 40 -> 15 -> 10).
- [x] It still trips and ragdolls exactly as before — `TAIL_TRIP_SPEED`
      and the trip push are untouched. Only damage changed.
- [ ] The operator plays it and agrees it feels right. *(They played
      the 4-hit version and asked for less; the 6-hit version is not
      yet play-tested.)*

## Out of scope

- The tail's reach, speed, or trip behaviour.

## Verification notes

The last box is deliberately **left unticked**. This is a balance
change, and balance cannot be settled by a test — only by playing it.
`tests/smoke_tail_damage.gd` still passes, but all it proves is that a
fast whip does *some* damage and a still tail does none; it would pass
just as happily at the old, too-strong numbers.

Iterating on it was cheap precisely because it is only two numbers,
and because trip/ragdoll behaviour was never entangled with damage —
`TAIL_TRIP_SPEED` and `TAIL_TRIP_SCALE` have not moved through any of
this, so the tail sweeps exactly as it always did.

Checked the arithmetic rather than trusting it: at a fast swing
(speed 40) the tail now does 9.2 damage, so 6.5 hits to kill.

**Verifying this needed a test fix first.** `smoke_tail_damage` and
`smoke_tail` both hosted a game to spawn a player, so neither could
run while the operator had delve open — exactly the STO-TOOLS-009
problem, blocking the very change being made. Both now spawn the
player directly and run alongside a live game. That is a down-payment
on STO-TOOLS-009, not the whole story: other tests still host.
