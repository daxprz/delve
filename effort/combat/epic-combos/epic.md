---
xid: EPI-COMBAT-COMBOS
parent: ../design.md
kind: epic
effort: combat
status: shipped
date: 2026-08-03
bd-id: delve-7yb
shipped: 2026-08-03
---

# Combo system

## Summary

A combo system that makes every character more fun: **chaining hits
multiplies your damage**, with an extra **air-chain bonus** while you're
airborne (swinging / flying / wall-jumping). All the characters' attacks
route through it, so the combos "swing→ram", "sprint→wall-jump→tail",
and "dive→snatch→drop" all pay off.

## Definition of Done

- [x] Chained enemy hits build a combo that multiplies damage.
- [x] Airborne hits get a bonus; the combo resets after a gap or a hit.

## Stories

| #   | Slug        | Size | Notes |
|-----|-------------|------|-------|
| 003 | combo-meter | M    | `deal_damage` routes all attacks; multiplier + air bonus. |

## Note

The on-screen "COMBO x…" text was removed at the operator's request; the
multiplier still works, just without the label.
