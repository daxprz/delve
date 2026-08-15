---
xid: DES-ENEMIES-002
parent: ./design.md
kind: design
effort: enemies
status: active
date: 2026-08-14
bd-id: delve-9600
---

# The Giant Spider

The official record of what this creature is. Everything the operator
has asked for, gathered from twenty-odd stories across three epics, in
one place — including the parts that are not built and the parts that
were tried and failed.

**Status key:** ✅ built · 📝 written, not built · ❌ tried, failed

---

## What it is for

Every other enemy in delve is a fight. This one is meant to be
**terrifying**, and the operator was precise about the difference:

> "makeing this creature tariffing"

Big is a health bar. Terrifying is being **taken** — picked up, dragged
off, spiked on something sharp, and left alive while it walks away.
A monster that kills you is a fight. A monster that takes you away and
leaves your friends a *choice* is a story that happens differently
every time.

There is **only ever one of it** (STO-ENEMIES-021). It is not a
creature you meet in pairs.

---

## The body ✅

Generated entirely in code and seeded from its name, so every spider is
its own individual and every machine builds the identical one.

| Property | Value |
|---|---|
| Health | 120 (a Walker is 60) |
| Speed | 1.6 m/s (a Walker is 3.0) |
| Damage | 18 (a Walker is 12) |
| Body block | ~0.30 × 0.17 × 0.40 m, seeded |
| Body height | **2.0–3.1 m** depending on seed |
| Leg length | **~5.4 m** total |
| Stability | far higher than a Walker — hard to topple |

### Shape

- **Four legs, three segments each** (STO-ENEMIES-021): down off the
  body, steeply **up** to a sharp knee, then a long way back **down** to
  the floor. Two segments could only manage out-up-down, which reads as
  a bent stick rather than a leg hanging off a body.
- Segment shares **0.13 / 0.19 / 0.68** (STO-ENEMIES-022) — two short
  joints near the body and one long reach to the ground. The operator
  asked for the last part to be "the longest by alot".
- Segment angles **0.55 / 2.65 / 0.10 rad**. The middle rises *steeply*
  rather than reaching outward, making the knee a sharp peak. At 2.20 it
  went out almost as much as up, which rounded the peak into a shrug.
- **Slender** (STO-ENEMIES-022): a small body slung under long thin
  legs. The legs, not the body, are what you see.
- **Towering** (STO-ENEMIES-020): the body rides above head height and
  you can walk underneath it. Derived from the leg geometry, never
  picked — choose a height instead and the feet float or sink.
- The extra joint near the body was added at the operator's request so
  the leg goes "down up down" (STO-ENEMIES-021).
- A **fourth foot segment** was added and then removed, also by request
  (STO-ENEMIES-025).

### Not achieved: the X from above ❌

STO-ENEMIES-023/028 asked for the legs to splay along diagonals so the
creature reads as an **X** when seen from directly above. Both signs of
a ±45° yaw were tried; neither produced diagonals — the feet landed
nearly axis-aligned and asymmetric. Reverted rather than left lopsided.
**Still outstanding.**

---

## How it moves ✅

- **Diagonal pairs** step together — front-left with back-right — so
  the other diagonal is always down and it is never unsupported. That
  is what makes it read as a crawler rather than a box sliding along.
- **A real crawl, not a sine wave** (STO-ENEMIES-023): the foot stays
  planted and sweeps steadily back while it carries weight, then lifts
  and returns forward quickly. A sine slides the foot through the floor
  the whole time.
- **Every step is different** (STO-ENEMIES-026), derived from
  (seed, which pair, which step number) — never from `randf()`, because
  the gait runs independently on every machine and a random number would
  give each peer a different-looking spider.
- Jittered per **pair**, not per leg: per-leg jitter desynchronised the
  diagonals, and the diagonals moving together is the whole reason it
  stays upright.
- **It lumbers.** Slow, deliberate, big strides (STO-ENEMIES-021).

### Floppiness ✅ (STO-ENEMIES-039)

The operator asked for both floppy options at once: *very loose and
rubbery*, **and** *able to go limp*. The combination is the point — a
limp limb only reads as damage because the others are already swinging
loosely.

Each joint is a damped spring chasing the angle the gait asks for, and
the **far joint is much softer than the near one**, so the end of a long
limb whips along behind the part near the socket. Equal stiffness would
lag the whole leg as one rigid piece.

| | Lag while walking at 1.6 m/s |
|---|---|
| STO-ENEMIES-037 (body-driven) ❌ | **1.4°**, decaying to 0.0 |
| STO-ENEMIES-039 (gait-driven) ✅ | **20–46°**, peaking at 59 |

Standing still it settles to **0.1°**, taking about **four seconds** to
do so — that slow settle is the feature, not a fault.

A hit knocks the life out of the limbs: they stop driving and dangle,
then gather themselves back up. The pincers fall open while limp,
because a limp claw cannot hold anything and it should be visible from
across the room that it cannot.

### Clambering ✅ (STO-ENEMIES-027)

It gets over **things** and is stopped by **walls**, and it decides
which is which by asking the world one question:

> **Can I see the top of this from here?**

Yes → clamber over it. No → it is a wall, go **around**. One
measurement, no list of obstacle names, so an obstacle nobody
anticipated gets the right answer for free.

The cut-off is **its own body height**, read off the creature rather
than typed in, so a bigger spider reaches higher with nothing to
re-tune. Blocked, it follows the face of the wall; square-on it picks a
side from a hash of its name, so every peer agrees and it cannot dither.

This **replaced** STO-ENEMIES-024, which let it climb anything and made
the big wall pointless.

---

## The pincer arms ✅ (STO-ENEMIES-030)

Two arms on the **front** of the body, each ending in a pincer of two
halves that opens and shuts like a beak. They weave **out of step** with
each other, because a perfectly mirrored pair reads as one object.

Measured: arms **3.13 m**, reach **3.82 m**, against a body **0.37 m**
wide. Sized from the body height, so they scale with the creature.

**Known concern, not yet judged:** the arms are *thinner* than the legs
(0.118 m vs 0.156 m) and shorter than them, bolted to a small block two
metres up inside a cage of four much larger limbs. They may not read as
pincers so much as a fifth and sixth leg. The operator has confirmed
they are visible; whether they look right is still open.

---

## What it does to you 📝

None of this is built. It is the whole of
**EPI-ENEMIES-SPIDER-TAKES-YOU**.

| # | | |
|---|---|---|
| 048 | The arms reach out for you | your warning that it is coming |
| 031 | The pincers hit hard | being caught must frighten you |
| 032 | They reach around and through things | cover is not safe |
| 033 | Sharp spikes exist in the world | something to be put on |
| 034 | It grabs you and impales you | the heart of it |
| 049 | The screen dims, then reddens | you always know which stage you are in |
| 050 | You bleed, and a timing game slows it | the clock you cannot stop |
| 035 | Your friends can pull you free | you cannot save yourself |
| 036 | If nobody comes, it eats you | limbs are left over |

### Being taken, start to finish (operator, 2026-08-14)

Described in full for the first time on this date:

1. Its **arms reach out toward you** as it gets close — procedurally,
   tracking wherever you actually are.
2. It **catches you** and **smashes you into the ground**.
3. It **drags you along the ground** and the **screen goes dimmer**. You
   stay on the floor and you can **look around** the whole way. Never
   lifted, never dangling.
4. It **puts you on a stick** — a spike. The **screen turns red** and you
   **can still kinda see**.
5. You **bleed on a clock**. A **timing game** slows the bleeding down;
   you play it to stretch out how long you last.

**The rule underneath it, and the best idea in this epic:** everything
you do to save yourself kills you faster. Struggling, fighting,
thrashing — all of it bleeds you out quicker, with no exception. Only
staying calm and playing the timing game buys you a moment, and only
someone else can actually free you.

It means the panicky, natural thing to do is the wrong thing, and the
player who lasts longest is the one who stops struggling and
concentrates.

**What you can still do while impaled:**

- **You can look around.** Not frozen. You watch it leave and you watch
  your friends arrive.
- **You can struggle** by mashing **Space** — each mash takes **0.01**
  off **your own life**. It never helps you.
- **You can fight back, but sometimes your attacks do nothing.** You are
  pinned and flailing, not fighting properly. **Every attempt makes you
  bleed faster.**
- **Momentum attacks always do nothing.** The Runner's dash, the pounce
  — anything powered by how fast you are going. A player nailed to a
  spike has no speed. This is not a special case; it is delve's existing
  rule (STO-CHARACTER-070) applied where it hurts.

Struggling alone must **never** be enough to free you. Someone has to
come.

---

## Its mind 📝

None of this is built. It is the whole of
**EPI-ENEMIES-SPIDER-LEARNS**, plus the radar it depends on.

### What it does today

Its entire brain, unchanged since the day it was made:

1. Find the nearest player — **through walls, at any distance, always**
2. Walk in a straight line at them
3. Stop when close
4. Rear back 0.55 s, swing, wait 1.8 s
5. Repeat

No memory, no strategy, no prediction. It cannot lose you, so it never
searches — and **searching is the first thing that reads as thinking**.

### Radar with memory 📝 (STO-ENEMIES-038) — build this first

It finds you by **sensing hitboxes**, not by being told. Whatever it
senses becomes its target and its **last known place**. Sense nothing
and it hunts that place instead. Arrive and find nothing, the trail
goes cold.

The memory is the point. Without it, radar is a worse version of
omniscience — lose sight and the creature freezes, which reads as
broken. With it, **breaking away is a real thing you can do**.

### The learning 📝 (STO-ENEMIES-043 to 047)

**It remembers you forever**, saved to a file. Come back tomorrow and it
already knows how you move.

It learns **all** of: which way you run, when you dodge and block, where
you hide, and which character you play.

It is **smart but makes mistakes** — it guesses, overcommits, and can be
baited. A monster you cannot fool is not frightening, it is unfair.

### The operator's insight, which makes this buildable

Asked whether it should work out walking from scratch:

> "give it basic knowlge of walking so it seems like its already existed
> before the player was there so it still needs to learn without having
> to go through hundreds of genorations"

That is the founding idea of the epic. It **starts already knowing
roughly how to walk** — because it existed before you turned up — and
refines from there. Never learns from zero, never needs hundreds of
generations, still genuinely learning. The same principle carries the
rest: start from something that works, then refine with what you
observe.

### The honest limit

**This is not a brain.** A creature that starts knowing nothing and
discovers walking needs neural networks and thousands of training runs,
which does not fit in delve. What is being built keeps score and adapts.
Played against it feels like learning and genuinely gets harder — but it
is bookkeeping and rules underneath, and "almost infinite" comes from
**combining many small behaviours**, not from one clever mind.

---

## Its body must be solid 📝 (EPI-ENEMIES-SOLID-SPIDER)

> "it should colide with everything even its other legs so it has to
> learn how to work aganst everything and even itself"

Self-collision is **the point**, not polish. The spider is meant to have
to work against a body that gets in its own way, and that constraint is
what the learning has to solve. Which fixes the order: **collision
before learning**, because learning to move inside a body that can pass
through itself is solving a problem that does not exist.

### Attempt 1 ❌ — reverted (STO-ENEMIES-041)

Treating each frame's limb pose as a proposal and refusing any that
entered geometry refused **10 segments per frame** and achieved nothing:

| | ON | OFF |
|---|---|---|
| deepest limb into a wall | 0.569 m | **0.568 m** |
| worst self-overlap | 0.1898 m | **0.1896 m** |

Refusing a pose freezes an **angle**, but where a limb *is* depends on
the angle **and where the body is** — and the body walks forward,
carrying the frozen limb in. The stored safe angle also goes stale.

Best candidate fix: **let the legs stop the body.** If a leg cannot find
a clear pose, the spider does not advance. That makes the world push
back, which is what the operator meant.

---

## Known faults

- **Its ragdoll is a third of a spider** (STO-ENEMIES-040). Knocked
  down, the skeleton has the block and two segments per leg. Missing:
  the **long bottom segment** (3.70 m of a 5.43 m leg — 68% of every
  leg) and **both pincer arms**. The real body is hidden, so what you
  see is a small block with eight stumps.
- **It camps on the practice dummy.** The dummy counts as a player,
  never runs and never stays dead, so the spider farms it forever and
  never comes for you.
- **The X-from-above silhouette was never achieved** (see above).

---

## Rules this creature is built on

Collected because each was learned the hard way and each still applies:

1. **Derive from the creature, never type in a number.** Body height
   comes from the leg geometry; clamber reach comes from body height;
   arm length comes from body height. A bigger spider works with nothing
   re-tuned.
2. **Never `randf()` in anything the peers must agree on.** Hash the
   seed with what varies. The same spider takes the same walk on every
   machine while never repeating itself.
3. **Guard with `has_method`, not a null check.** Calling a humanoid's
   `buckle_leg` on a four-legged body crashed the game on every medium
   hit, and every existing test used a full ragdolling blow and sailed
   past the broken tier.
4. **Provoke a feature the way play provokes it.** The floppiness tests
   shoved the spider at 14 m/s — nine times its walking speed — and
   reported a feature that measured 1.4° in play.
5. **A check that proves the code ran is not a check that it worked.**
