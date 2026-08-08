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

Now: **x 0.35, capped at 15**, so a whole enemy takes at least four
solid hits.

## Definition of Done

- [x] The tail deals noticeably less damage (cap 40 -> 15).
- [x] It still trips and ragdolls exactly as before — `TAIL_TRIP_SPEED`
      and the trip push are untouched. Only damage changed.
- [ ] The operator plays it and agrees it feels right.

## Out of scope

- The tail's reach, speed, or trip behaviour.

## Verification notes (2026-08-07)

The last box is deliberately **left unticked**. This is a balance
change, and balance cannot be settled by a test — only by playing it.
`tests/smoke_tail_damage.gd` still passes, but all it proves is that a
fast whip does *some* damage and a still tail does none; it would pass
just as happily at the old, too-strong numbers.

If four hits feels like too many, this is one number to change.
