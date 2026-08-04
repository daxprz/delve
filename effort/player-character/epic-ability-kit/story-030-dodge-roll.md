---
xid: STO-CHARACTER-030
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-7kf
tasks: 2
complete: 2
---

# Runner dodge roll: fast invincible roll

## Summary

The Runner presses **C** to **dodge-roll**: a quick burst in the movement
(or facing) direction during which the Runner is **invincible**. Once the
roll ends, damage lands normally again — a skill move for slipping past danger.

## Definition of Done

- [x] C starts a fast roll (`ROLL_SPEED` for `ROLL_TIME`) in the input/facing
      direction.
- [x] `take_damage` is ignored while rolling; normal after it ends.

## Verification notes (2026-08-03)

- `player.gd`: `do_dodge()` picks a direction and sets `_rolling`; `_roll_move`
  drives the burst and overrides movement; `take_damage` returns early while
  `_rolling`. Same guard key (C) as the Grabber's block, gated per character.
- `tests/smoke_dodge.gd`: **PASS** — took no damage from a 50-hit mid-roll,
  rolled ~5.6 m, then took damage normally after the roll.

## Out of scope

- A dodge cooldown / stamina; i-frame tuning; roll-cancel into attacks.
