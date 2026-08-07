---
xid: STO-CHARACTER-037
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-3bq
shipped: 2026-08-07
tasks: 4
complete: 4
---

# Guardian character (blank slate)

## Summary

The **Guardian** joins the roster: a plain humanoid like the others,
but **noticeably bigger** — taller and broader than every other
character, so it reads as the big one at a glance. More health to
match its size. No special powers yet; its shielding play style is a
later epic.

## Definition of Done

- [x] "Guardian" is pickable on the character-select screen.
- [x] Its body is visibly larger than the other characters (scaled
      up, not just wider), with a matching collision capsule and
      camera height so it still fits through doorways and sees over
      its own body.
- [x] Walks, jumps and works in multiplayer like any other character.
- [x] No shielding / revive powers yet.

## Out of scope

- The Guardian's actual co-op play style (shields, blocking hits for
  a teammate, reviving) — its own epic.

## Verification notes (2026-08-07)

- Head height 2.25 m vs the Runner's 1.66 m; collision capsule 2.43 m
  vs 1.80 m; eye height 2.16 m vs 1.60 m — body, hitbox and camera all
  scale together, so the Guardian can't see out of its own chest or
  squeeze through gaps it shouldn't.
- Health 220 (the tank of the roster), a little slower than the rest.
