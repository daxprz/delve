# Where we're up to

Last updated 2026-08-14. Everything below is committed and pushed,
and the suite is green.

---

## 🎮 Try these next time you play

Restart Play first — a running game keeps the old code.

1. **The Grabber's piston.** Press **`F`**: the arms fold together over
   half a second into a machine with a big bolted plate on the front.
   Hold **`LMB` + `RMB`** to charge, let go to drive it out. It is
   **heavy** — swing round and it drags behind you. You can still grab
   things with it.
2. **The giant spider.** Towers over you on three-jointed splayed
   legs, and **every step it takes is different**.
3. **The Runner's claws** — `LMB` / `RMB`. Damage is **100% momentum**:
   0.10 standing, 0.25 walking, 0.50 sprinting, **1.00 dashing**.
4. **Double-tap `W`** to dash.
5. **`E`** cycles the Grabber between grab and punch.

---

## 🔨 Asked for, written down, NOT built

| # | what |
|---|---|
| **STO-CHARACTER-073** | the piston's push should come from its own **momentum** — a slow stroke nudges, a fast one throws. *Last item of that story.* |
| **STO-COMBAT-004** | a thrown object hurts what it hits — **build this first, the rest need its rule** |
| **STO-COMBAT-005** | smashing a held enemy into a wall hurts it |
| **STO-COMBAT-006** | hitting an enemy with an enemy hurts both |
| **STO-COMBAT-007** | `E` crushes the body part you are holding |
| **a boss** | you asked for one; it is an entry in the enemy registry now |

---

## 🧩 Unfinished, with the reason written down

- ~~**STO-ENEMIES-024 — wall climbing.**~~ **Settled by
  STO-ENEMIES-027:** the spider now gets over *things* (crates, low
  ledges) and is **stopped by walls**, which is what you asked for. The
  old stall no longer matters — it stalled on a wall it is not supposed
  to climb. Blocked, it now goes **around**.
- **The piston in multiplayer is unverified.** Much less risky now
  that nothing is spawned — the arms already exist on every machine,
  so only the launch crosses the network.
- **Riding the piston plate** as it extends: it is solid enough to
  stand on, but moving WITH it is unproven.

---

## 🛠️ Jobs for me, not you

**STO-TOOLS-009 is the one that matters.** ~22 tests still cannot run
while you have the game open, because they need port 7777. It has now
bitten twice:

- **v0.1.9 shipped with two failing tests** nobody knew about
- `smoke_abilities` sat asserting that `C` still blocks, long after
  you made it a dead key

Both times the symptom was identical: a test quietly asserting a
decision you had already reversed, hidden for days.

**Partly defused (2026-08-14).** There is now a real runner,
`scripts/run_suite.sh`, instead of me retyping the loop each time. It
warns up front when the port is held, prints skipped tests by name, and
ends with "skipped tests are NOT verified". Two things it taught me
immediately:

- The port is **UDP**. `ss -ltn` shows 7777 as free while the game is
  plainly holding it, so my old check was looking at the wrong thing
  and I twice believed the port was free when it was not.
- The `_client` half of a paired test can never pass alone — it dials a
  host that is not there. The runner now drives the pair through
  `run_mp_test.sh` instead of scoring the client half as a failure.

The underlying problem stands: the tests still want port 7777. The real
fix is to let them use a different one.

---

## ✅ Shipped since v0.1.11

Enemy kinds registry · the giant spider (X legs, unique steps, partial
climbing) · the Runner's dash and momentum claws · the Grabber's
piston (mode, folding arms, shield plate, heavy turn, grabbing) ·
procedural fingers that wrap and grip · the spider ragdoll crash fix.

**Not released.** v0.1.11 is still the newest download. The version in
`project.godot` is already bumped to **0.1.12**, so cutting one is just
tagging `v0.1.12` — but do it with the game CLOSED, or ~22 tests skip
and go out unverified. That is how two broken tests shipped in v0.1.9.

---

## 📝 Three lessons worth keeping

- **A function working is not the same as a key working.** Three bugs
  in one day: a bool that could only reach two of three modes, a test
  calling the function directly, and a key handler that was never
  added. All three had green tests.
- **"Visible" was true and useless.** The piston plate was visible —
  40 m away at the world origin. *Visible and WHERE* was the question.
- **Guarding one door is not guarding the room.** Blocking the aim
  path still left `grab_body` wide open.
