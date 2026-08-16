---
xid: STO-CHARACTER-067
parent: ./epic.md
kind: story
effort: character
size: L
status: removed
date: 2026-08-14
depends-on: []
bd-id: delve-eblv
---

# F combines the arms into a chargeable piston

## ⛔ REMOVED from the Grabber (2026-08-16)

The Grabber was remastered into a claw-machine claw
(EPI-CHARACTER-GRABBER-CLAW) and every one of its abilities was taken
out at the operator's request — four abilities, four keys and seven
unfinished piston stories traded for one idea a child can describe in
a sentence.

**This story is kept, not deleted**, the way the Guardian and Builder
were. What it measured and the bugs it found outlive the feature.

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

- [x] `F` toggles the arms into a piston, and back.
- [x] Both mouse buttons charge it; either alone does not.
- [x] Charging longer launches harder — 6.9 for a tap, 34.0 full.
- [x] A tap still fires, at a fifth of the power.
- [x] An enemy hit by it is launched **and ragdolled**.
- [x] A player is launched at 34 m/s with **no ragdoll and no roll**.
- [x] It does no damage to the player it launches.
- [ ] Firing at nothing wastes the charge, so it cannot be held
      forever.
- [x] The pull is gone from `F` — no overloading.
- [x] Only the Grabber has it.
- [ ] **Multiplayer NOT verified.** The RPC is written but no
      two-instance test exists yet.
- [x] `tests/smoke_piston.gd`. The two-instance test is still owed.

## Verification notes (2026-08-14)

A real bug surfaced immediately: `launch_by_piston` deferred to the
node's multiplayer authority — but **offline there is no authority to
defer to**, and a player node named "2" is not "ours" even with no
network at all. The launch took the network path and vanished. It now
checks for an actual peer first.

One thing is deliberately **printed, not asserted**: how far the
launched player travels. A second player node offline does not run its
own movement, so it never moves however much velocity it has. That is
an artefact of two players sharing one machine, which never happens in
a real game — each peer owns its own player. The launch itself is
proven (34 m/s applied, no ragdoll, no damage); the travel belongs in
a two-instance test that does not exist yet.

## Out of scope

- Launching a player who does not want to be launched (no consent
  check for now — it is a co-op game).
- The piston having its own model. The two arms lock together.

## Notes — things to be careful of

- **`F` was `ability_pull`. SETTLED: the pull is REMOVED** and F
  belongs to the piston outright. The operator chose that rather than
  moving the pull to another key, so there is no overloading and no
  risk of the pull seeming to "randomly stop working". The pull's code
  is unhooked rather than deleted, the same way C and G were
  (STO-CHARACTER-056), so it can come back on another key in one line.
- **A launched player must not be ragdolled by their own landing**
  either. Landing hard already causes fall damage; a piston launch
  should be exempt or it will kill the person you were helping.
- Multiplayer is the hard half. Damage and knockback for players
  already have to cross the network the right way round
  (STO-ENEMIES-011) — a launch is the same problem, and getting it
  wrong means the launcher sees a flying friend who never moved.
