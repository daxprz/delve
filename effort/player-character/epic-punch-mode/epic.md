---
xid: EPI-CHARACTER-PUNCH-MODE
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-03
bd-id: delve-0fi
shipped: 2026-08-03
---

# Momentum punch mode (Grabber)

## Summary

For the **Grabber** character: press **E** to switch between **grab
mode** (swing to build momentum) and **punch mode**. In punch mode you
can't grab — instead you punch, and **the more momentum you have, the
harder the punch**. A powerful enough punch makes a **shockwave**. The
loop: swing to get fast → press E → smash into something.

## Definition of Done

- [x] E switches grab-mode / punch-mode (Grabber only).
- [x] In punch mode the hands can't grab.
- [x] Punch power scales with the player's momentum.
- [x] A powerful enough punch spawns a shockwave.

## Stories

| #   | Slug            | Size | Notes |
|-----|-----------------|------|-------|
| 007 | mode-toggle     | M    | E switches modes; no grabbing in punch mode. |
| 008 | momentum-punch  | L    | Punch power = base + player speed; knockback. |
| 009 | shockwave       | M    | Powerful punch → radial shockwave. |

## Note

There are no enemies yet, so punches currently hit **physics bodies**
(the box). When enemies are added they'll react to the same punch +
shockwave. Applies to the Grabber only (the Runner has no arms).
