---
xid: STO-CHARACTER-067
parent: ./epic.md
kind: story
effort: character
size: L
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-eblv
---

# F combines the arms into a chargeable piston

## Summary

Press **F** and the Grabber's two arms lock together into a single
**piston**. Hold **LMB and RMB together** to charge it — the longer
you hold, the more powerful — and release to fire.

What it hits depends on what it is:

| target | what happens |
|---|---|
| an **enemy** | launched hard, and **ragdolled** |
| another **player** | launched hard, and **NOT ragdolled** |

That difference is the whole point. A launched player keeps control,
so the Grabber can fire a **Runner** across the map — and the Runner
arrives at speed, which now matters enormously because its claw damage
comes entirely from momentum (STO-CHARACTER-066). A Runner launched by
a piston lands the hardest scratch in the game.

Two players, one combo, neither able to do it alone. That is worth
building carefully.

## Definition of Done

- [ ] `F` toggles the arms into a piston, and back.
- [ ] Holding **both** mouse buttons charges it; either alone does
      not.
- [ ] Charging longer launches harder — measured, not eyeballed.
- [ ] A full charge is dramatic; a tap is feeble.
- [ ] An enemy hit by it is launched **and ragdolled**.
- [ ] A player hit by it is launched and **stays in control** — no
      ragdoll, no stagger, no lost input.
- [ ] It does not hurt the player it launches. This is a boost
      between friends, not an attack.
- [ ] Firing at nothing wastes the charge, so it cannot be held
      forever.
- [ ] Only the Grabber has it.
- [ ] Works in multiplayer: the launched player is launched on THEIR
      machine, not just on the launcher's screen.
- [ ] Proven by a headless test, and a two-instance test for the
      player launch.

## Out of scope

- Launching a player who does not want to be launched (no consent
  check for now — it is a co-op game).
- The piston having its own model. The two arms lock together.

## Notes — things to be careful of

- **`F` is currently `ability_pull`.** Overloading it means the pull
  either moves or goes. Decide before building, and check it never
  feels like the pull "randomly stopped working" — the same risk
  flagged in STO-COMBAT-007 for `E`.
- **A launched player must not be ragdolled by their own landing**
  either. Landing hard already causes fall damage; a piston launch
  should be exempt or it will kill the person you were helping.
- Multiplayer is the hard half. Damage and knockback for players
  already have to cross the network the right way round
  (STO-ENEMIES-011) — a launch is the same problem, and getting it
  wrong means the launcher sees a flying friend who never moved.
