---
xid: EPI-CHARACTER-ABILITY-KIT
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-03
bd-id: delve-9zb
shipped: 2026-08-13
---

# Ability kit: zip, throw, pull, block, heal, dodge

## Summary

A batch of new **abilities** that make the characters more fun to play —
each one a **remix of a system we already built** (grapple, carry,
knockback, fall damage, health). The Grabber gets a defensive+utility kit;
the Runner gets a mobility escape; everyone slowly heals.

## Definition of Done

- [x] Grabber: **grapple-zip** (Q), **throw** (G), **pull** (F),
      **block/parry** (C).
- [x] Runner: **dodge roll** (C, invincible).
- [x] All characters: **heal-over-time**.
- [x] Every ability covered by a headless smoke test.

## Stories

| #   | Slug         | Size | Notes |
|-----|--------------|------|-------|
| 025 | grapple-zip  | M    | Q dashes to the aimed point. |
| 026 | throw        | M    | G grab a box/enemy, G again to hurl it. |
| 027 | pull         | S    | F yanks an enemy toward you. |
| 028 | block-parry  | M    | Hold C to block (25% dmg), tap C to shove. |
| 029 | heal         | S    | Slow regen after a lull (all characters). |
| 030 | dodge-roll   | M    | Runner: fast invincible roll on C. |

## Controls added

`ability_zip`=Q, `ability_throw`=G, `ability_pull`=F, `ability_guard`=C.

## Tests

`tests/smoke_abilities.gd` (Grabber kit + heal) and `tests/smoke_dodge.gd`
(Runner roll) — both **PASS**, and the full suite + paired MP test are green.
