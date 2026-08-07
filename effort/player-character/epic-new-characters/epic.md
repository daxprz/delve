---
xid: EPI-CHARACTER-NEW-CHARACTERS
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-07
bd-id: delve-2zj
shipped: 2026-08-07
---

# Three new characters: Guardian, Sniper, Builder (blank slates)

## Summary

Adds three new characters to the roster. Their **play-style powers**
are deliberately left for later epics, but each gets its own
**distinctive body** now, so they look and feel like different
creatures from the moment you pick them:

- **Guardian** — noticeably BIGGER than everyone else.
- **Builder** — FOUR arms.
- **Sniper** — big ears, and **blind**: it cannot see the world
  normally. Anything that MOVES sends out an echo, and the echo
  outlines the map around it — so the Sniper sees by sound.

Each was chosen for a completely different PLAY STYLE (a different
verb), unlike the current roster which all chase-and-hit:

- **Guardian** — plays for the other player: shields, blocks hits
  meant for them, revives them. Only meaningful in co-op.
- **Sniper** — plays at long range: slow and fragile, hits from far
  away. Everyone else must close distance; the Sniper must keep it.
- **Builder** — makes things instead of fighting: places blocks,
  ramps and bridges to reshape the world.

Deliberately blank so the roster grows first and the powers can be
designed and tested one at a time.

## Definition of Done

- [x] Guardian, Sniper and Builder appear on the character-select
      screen and can be chosen.
- [x] Each spawns, walks, jumps and works in multiplayer like any
      other character.
- [x] Guardian is visibly bigger; Builder has four working arms;
      Sniper has ears and sees by echo instead of sight.
- [x] No play-style powers yet (no shielding, no ranged shot, no
      block placing) — those are later epics.
- [x] Existing characters (Grabber, Runner, Flyer) are unchanged.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 037 | guardian | S | Bigger body + select entry |
| 038 | sniper | S | Ears + select entry |
| 039 | builder | S | Four arms + select entry |
| 040 | sniper-echo | L | Blind vision: movement emits echoes that outline the map |

## Later (not this epic)

Each character's actual play style becomes its own epic once we
design it — Guardian shielding, Sniper ranged shooting, Builder block
placement.
