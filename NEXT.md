# Where we're up to

Last updated 2026-08-14. Everything below is committed and pushed,
and the suite is green (**53 pass, 0 fail**, 24 skipped for the port).

---

## 🎯 Start here next time

**Build STO-ENEMIES-038 — the radar with memory.** It is the
foundation of everything you asked for about the spider being smart.

Right now the spider finds you by looking up every player in the game,
through walls, at any distance, always. It can never lose you, so it
never has to search — and **searching is the first thing that reads as
thinking**. An omniscient creature has no reason to be clever.

You already decided how it should work: it finds you, and when it
loses you it **remembers where you were** and goes there. Every other
learning story needs that piece anyway.

Second choice: **STO-ENEMIES-041**, the limb collision that failed
today. Two candidate fixes are written into the story.

---

## 🎮 Try these next time you play

Restart Play first — a running game keeps the old code.

1. **The giant spider walking.** This is the new one. Its legs now trail
   **20–46°** behind where the gait is telling them to be, and the long
   bottom segment whips along behind the knee. Stand still and let it
   walk to you. When it stops, the legs take about **four seconds** to
   settle rather than snapping still.
2. **The spider's pincer arms** — two arms on the front with jaws that
   open and shut, weaving out of step with each other.
3. **The practice dummy**, standing left of spawn at `(-3, 0, -4)`. Hit
   it, and enemies attack it like a real player.
4. **The spider clambering.** It climbs over crates and low ledges but
   is stopped by real walls, and goes **around** them.
5. **The Grabber's piston.** `F` to fold the arms into it, hold
   `LMB`+`RMB` to charge.
6. **The Runner's claws** — damage is 100% momentum: 0.10 standing,
   0.25 walking, 0.50 sprinting, **1.00 dashing**. Double-tap `W` to
   dash.

---

## 🐛 Known bugs, found and not yet fixed

- **The spider camps on the dummy forever.** It is 0.9 m from it,
  beating it to 0 hp over and over while you stand across the map. The
  dummy counts as a player, never runs and never stays dead, so the
  spider found an infinite target and will never come for you. Fix it
  when the radar lands — probably "prefer a real player when there is
  one".
- **The spider's ragdoll is a third of a spider.** Knock it down and
  the ragdoll skeleton contains the block and two segments of each leg.
  Missing: the **long bottom segment** (3.70 m of a 5.43 m leg — 68% of
  every leg) and **both pincer arms**. The real body is hidden, so what
  you see is a small block with eight stumps. Story **STO-ENEMIES-040**.
  The Foot segment is an old gap; the pincers are mine, added after the
  skeleton was written.

---

## 🔨 Asked for, written down, NOT built

### The spider's mind — nothing here exists yet

| # | what |
|---|---|
| **STO-ENEMIES-038** | radar: it finds you by sensing, and **remembers where you were** ← *start here* |
| **STO-ENEMIES-043** | it tunes its own walk, starting from one that already works |
| **STO-ENEMIES-044** | it copes when hurt or blocked |
| **STO-ENEMIES-045** | it remembers you **forever**, saved to a file |
| **STO-ENEMIES-046** | it learns your running, dodging, hiding, character |
| **STO-ENEMIES-047** | it picks strategies, and sometimes the wrong one |

**The honest limit is written at the top of that epic:** this is
bookkeeping and rules, not machine learning. It will feel like learning
and it will genuinely get harder, but it is not a brain.

**Your idea is what makes it buildable** — the spider starts already
knowing roughly how to walk, "so it seems like its already existed
before the player was there", and refines from there instead of
learning from nothing over hundreds of generations.

### The spider taking you

| # | what |
|---|---|
| **STO-ENEMIES-031** | the pincers hit hard |
| **STO-ENEMIES-032** | the pincers reach around and through cover |
| **STO-ENEMIES-033** | sharp spikes in the world |
| **STO-ENEMIES-034** | it grabs you and impales you — you are **dragged along the ground**, and while pinned you can look around, mash Space for −0.01 off the timer, and your momentum attacks do nothing |
| **STO-ENEMIES-035** | your friends pull you free |
| **STO-ENEMIES-036** | if nobody comes, it eats you and leaves limbs |

### Solid body, and older items

| # | what |
|---|---|
| **STO-ENEMIES-041/042** | limbs collide with the world and with each other — **attempt 1 failed, see below** |
| **STO-ENEMIES-040** | the whole spider ragdolls, not a third of it |
| **STO-COMBAT-004** | a thrown object hurts what it hits — **build first, the rest need its rule** |
| **STO-COMBAT-005/006/007** | smash into walls · enemy-vs-enemy · `E` crushes the held limb |
| **a boss** | still just an entry in the enemy registry |

---

## ❌ Tried today and it did not work

**STO-ENEMIES-041 — limb collision, attempt 1. Reverted.**

I treated each frame's limb pose as a proposal: ray-check every
segment, and any that would end up inside the world keeps its previous
joint angle. It refused **10 segments per frame** and changed nothing:

| | collision ON | collision OFF |
|---|---|---|
| deepest limb into the wall | 0.569 m | **0.568 m** |
| worst self-overlap | 0.1898 m | **0.1896 m** |

Refusing a pose freezes an **angle**, but where a limb *is* depends on
the angle **and where the body is** — and the body keeps walking
forward, carrying the frozen limb in. The stored "safe" angle also goes
stale: clean a metre back, buried in the wall once the body advances.

Two candidate fixes are written into the story. The more promising one
is **let the legs stop the body**: if a leg cannot find a clear pose,
the spider does not advance. That makes the world genuinely push back,
which is what you meant by "it has to learn how to work against
everything and even itself".

---

## 🛠️ Jobs for me, not you

**STO-TOOLS-009.** ~24 tests still cannot run while you have the game
open, because they need port 7777. It has bitten twice: v0.1.9 shipped
with two failing tests, and `smoke_abilities` sat asserting `C` still
blocks long after you made it a dead key.

**Partly defused.** There is a real runner now, `scripts/run_suite.sh`.
It warns when the port is held, names every skipped test, and ends with
"skipped tests are NOT verified". It taught me two things immediately:
the port is **UDP**, so `ss -ltn` reports 7777 free while the game
plainly holds it; and the `_client` half of a paired test can never
pass alone, so it is now driven through `run_mp_test.sh`.

The real fix is still to let the tests use a different port.

---

## ✅ Shipped since v0.1.11

The practice dummy · the spider's pincer arms · floppy limbs you can
actually see · clambering over things but not walls · the suite runner.
Plus, from earlier: enemy kinds, the giant spider, the Runner's dash
and momentum claws, the Grabber's piston, procedural fingers.

**Not released.** v0.1.11 is still the newest download. `project.godot`
is already at **0.1.12**, so cutting one is just tagging `v0.1.12` —
but do it with the game **CLOSED**, or ~24 tests skip and go out
unverified. That is how two broken tests shipped in v0.1.9.

---

## 📝 Lessons worth keeping

- **Provoke a feature the way play provokes it.** The floppiness tests
  passed while shoving the spider at **14 m/s** — nine times its
  walking speed of 1.6, something the game never does. Measured while
  merely walking, the floppiness was **1.4°** and invisible. A test
  that hits something nine times harder than the game ever will is not
  testing the game.
- **A check that proves the code RAN is not a check that it WORKED.**
  The failed collision refused 10 segments a frame and moved the real
  measurements by a millimetre. The only check that told the two builds
  apart measured that my code executed.
- **Health is not position.** The dummy revived at full health five
  metres from where it had been standing. Every check passed, because
  none of them looked at *where*.
- **A function working is not the same as a key working.**
- **"Visible" was true and useless** — the piston plate was visible,
  40 m away at the world origin.
- **Guarding one door is not guarding the room.**

---

## 🙋 One thing only you can close

STO-ENEMIES-039 has a deliberately unticked box:

> **The operator looks at it and agrees it is floppy.** Until then this
> story is not done, whatever the numbers say.

The measurements say 20–46°. You have not confirmed it looks right yet.
Same goes for the pincer arms — I have never seen either of them.
