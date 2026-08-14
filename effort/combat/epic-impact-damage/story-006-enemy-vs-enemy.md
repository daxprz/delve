---
xid: STO-COMBAT-006
parent: ./epic.md
kind: story
effort: combat
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-be9
---

# Hitting an enemy with an enemy hurts both

## Summary

Swing the body you are holding into another enemy and **both** get
hurt and knocked down. Two enemies, one swing.

This is the payoff of the whole epic — the moment where holding a body
stops being a way to move it and becomes a way to fight with it.

## Definition of Done

- [ ] Swinging a held enemy into another enemy damages **both**.
- [ ] Both ragdoll if the hit is hard enough.
- [ ] A slow bump does nothing to either.
- [ ] Neither takes damage twice from one impact.
- [ ] It does not set off a chain reaction of bodies endlessly
      re-hitting each other.
- [ ] Proven by a headless test checking both health bars.

## Depends on

**STO-COMBAT-004** — the same impact rule, pointed at a body instead
of a wall.
