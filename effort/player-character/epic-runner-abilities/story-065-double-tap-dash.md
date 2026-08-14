---
xid: STO-CHARACTER-065
parent: ./epic.md
kind: story
effort: character
size: S
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-2if
---

# Double-tap W to dash

## Summary

Tap **W twice quickly** and the Runner **dashes** — a short burst of
speed in the direction it is already going.

It suits the Runner more than anyone: it is the character built around
movement, and it lost its dodge roll when C became a dead key
(STO-CHARACTER-056), so it currently has nothing quick at all.

## Definition of Done

- [ ] Two taps of W close together trigger a dash.
- [ ] Two taps far apart do NOT — walking normally must never dash by
      accident.
- [ ] The dash is clearly faster than sprinting, and short.
- [ ] Only the Runner can do it.
- [ ] It cannot be held down for permanent speed — one dash per
      double-tap, with a cooldown.
- [ ] Proven by a headless test measuring distance covered.

## Out of scope

- Dashing sideways or backwards.
- Dashing in mid-air.
