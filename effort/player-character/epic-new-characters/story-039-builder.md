---
xid: STO-CHARACTER-039
parent: ./epic.md
kind: story
effort: character
size: S
status: abandoned
date: 2026-08-07
depends-on: []
bd-id: delve-7y2
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Builder character (blank slate)


> **ABANDONED 2026-08-07.** The operator asked to remove this
> character. All of its code was reverted; see the epic for what was
> kept and what went.

## Summary

The **Builder** joins the roster: a humanoid with **four arms** — the
normal pair plus a second pair below them, all built and animated by
the same procedural body code, so all four swing as it walks. No
building powers yet; placing blocks is a later epic.

## Definition of Done

- [x] "Builder" is pickable on the character-select screen.
- [x] Its body has FOUR arms (two pairs), each a full
      shoulder/upper/forearm/hand chain.
- [x] All four arms animate with the walk, not just the top pair.
- [x] Walks, jumps and works in multiplayer like any other character.
- [x] No block placing yet.

## Out of scope

- The Builder's actual play style (placing blocks, ramps, bridges) —
  its own epic.
- Arms that do different jobs (e.g. lower pair carrying) — for now
  all four are cosmetic and animated.

## Verification notes (2026-08-07)

- All four arms present as full shoulder/upper/forearm/hand chains
  (UpperArmL/R + LowerUpperArmL/R) and all four are animated — the
  walk-swing code was rewritten to track each arm's side, since it
  previously assumed exactly two arms.
- The lower pair swings slightly behind the upper pair so the four
  don't move as one block.
