---
xid: STO-CHARACTER-033
parent: ./epic.md
kind: story
effort: character
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-j94
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Pounce cooldown: 15s, refunded on a hit

## Summary

The pounce (STO-CHARACTER-032) gets a **15 second cooldown** — but
landing it on an enemy **refunds the cooldown instantly**, so a Runner
who keeps connecting can chain pounces forever, while a miss grounds
the ability for 15 s. A hit is registered when the player passes
within 1.5 m of an enemy at any point during the pounce arc. While on
cooldown, holding Space does nothing (no crouch, no charge) — Space
falls through to nothing rather than silently eating the input.
Adds a HUD bar (above health, matching the Flyer's fuel bar): green
when ready, amber and refilling while recharging, so the lockout is
legible instead of the jump mysteriously not working.

## Definition of Done

- [x] Pounce starts ready; a missed pounce sets a 15 s cooldown.
- [x] Holding Space during cooldown does not crouch, charge or launch.
- [x] Connecting with an enemy mid-pounce zeroes the cooldown, so it
      can be re-charged immediately.
- [x] HUD bar shows cooldown state (green ready / amber refilling).
- [x] `tests/smoke_pounce_cooldown.gd` passes headless (6 checks).

## Out of scope

- Pounce damage / knocking the enemy down on impact — the pounce
  currently only registers the hit for the refund. Worth a follow-up
  now that enemies have tiered reactions.
- Cooldown on the Grabber/Flyer (they have no pounce).

## Verification notes (2026-08-07)

- 6/6 PASS: miss → 13.6 s remaining on landing (15 s minus flight
  time); a blocked attempt neither crouches nor reduces the timer;
  pouncing into a parked enemy refunds to 0.0 with the hit flag set.
- `smoke_pounce` regression PASS.
- smoke_health / smoke_flyer failed on "missing player" — the
  operator's editor Play session (pid 32731) holds port 7777, the
  known hosting-test block. Not related to this change.
