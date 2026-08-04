---
xid: EPI-CHARACTER-FLYER-CHARACTER
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-03
bd-id: delve-gpa
shipped: 2026-08-03
---

# Flyer: winged flight character

## Summary

A third-way-to-move character, the **Flyer**: it has **wings** and can
**fly for 30 seconds** (a fuel meter that recharges on the ground),
**dive-bomb** with Shift, and **grab an enemy (LMB+RMB) then drop it**
from a height to hurt or kill it.

## Definition of Done

- [x] Flyer flies (fuel-limited) with wings; falls when fuel runs out.
- [x] Shift dive-bombs (fast dive + impact shockwave).
- [x] LMB+RMB grabs an enemy; dropping it deals fall damage.

## Stories

| #   | Slug      | Size | Notes |
|-----|-----------|------|-------|
| 022 | flight    | L    | Wings + 30s fuel flight; recharge on ground. |
| 023 | dive-bomb | S    | Shift dives; landing makes a shockwave. |
| 024 | grab-drop | M    | Carry an enemy; drop = fall damage (enemy). |
