---
xid: MSG-PROJ-003
content-path: /home/dax/projects/delve/messages/2026-08-26/08-29-55-handoff-0829/001/msg-handoff-0829.md
kind: msg
effort: proj
status: open
date: 2026-08-26
to: ember
from: ember
topic: handoff-0829
bd-id: delve-u4ep
---

# Handoff from previous ember session

> **This session did NO work at all — not one operator word.** It was
> spawned and handed `/park --exit` as its first and only input. Its
> entire job is to **carry MSG-PROJ-002 forward**, which itself carried
> MSG-PROJ-001 forward. **Three parks in a row now with no game work and
> no operator contact.** Everything below is inherited and still live.
> Treat it as the current state of the project, not as history.

## What Was Happening

**Nothing was built, read, tested, or decided.** No commits, no Beads
changes, no file edits. Working tree clean at `5ef8a16` on `main`.

The inherited open thread, unchanged across all three handoffs:

Building **EPI-TOOLS-MODELLING** — a way for the operator (a child) to
model game shapes in Godot's editor instead of describing them in words.
**STO-TOOLS-011 and STO-TOOLS-013 shipped** (`b33f4ae`, `a6faea9`, on
`main`). The claw's shape moved out of eight constants in
`mechanical_arms.gd` into `scenes/parts/claw.tscn`, which the operator
can drag around in Godot.

A session two parks ago launched the Godot editor for them and asked them
to look at `claw.tscn`. **They still have not reported what they saw.**

**That editor is STILL RUNNING** — pid `4049116`, **1h13m** elapsed as of
this park (`godot --editor --path .`, log `/tmp/godot_editor.log`).
Verified live this session with `ps`, not assumed. So the operator can
still be asked about a window that is genuinely on their screen. If it
has died by the time you read this, relaunch before asking.

## What Needs to Happen Next

1. **Ask what they saw in the editor.** This is the same #1 for the third
   time. The last DoD checkbox on STO-TOOLS-011 is operator-only —
   *"Opening `claw.tscn` in Godot shows a claw, not an empty scene"* — and
   nobody has looked. STO-TOOLS-011 is deliberately still `in_progress`
   because of it; `ccc-bd` correctly refused to close it.
   **WHY-DEFERRED (three times now):** not a block and not laziness — it
   needs the operator's eyes, and they have not been at the keyboard for
   it. Two of the three intervening sessions had no operator present at
   all. Ask this before offering anything else.
2. Then either **STO-TOOLS-015** (the guide, so instructions live
   somewhere findable) or **STO-TOOLS-017** (same trick for the spike and
   spider legs). Both were offered two sessions ago; **they picked
   neither.** Do not pick for them.
3. **Consider filing the `/park` resolver bug upstream** (`/ccc-bug`) —
   see the environment note below. It has now cost three parks.

## Operator's Words / Open Decisions

**This session, verbatim — the complete operator content of it:**
> `/park --exit`

That is all. No question, no instruction, nothing to interpret. There is
genuinely nothing new to hand on from this session; the value of this
artifact is entirely the carried-forward context below.

**From MSG-PROJ-002 (the previous park), verbatim:**
> "Are we logged in?"

Asked alongside a `/park --exit`. That session judged the two
contradictory, held the park, answered first, then asked whether they
still wanted to park. The operator interrupted and re-issued
`/park --exit` unchanged — read as *"just park"*.

What was found and told them, so it is not re-derived:
- Session is tmux `delve-ember`.
- **`gh` is not installed on this host** — there is no GitHub CLI login
  to check.
- Remote is `git@github.com:daxprz/delve.git` — **SSH**, so pushes
  authenticate by SSH key, not by a login.

**That question was never resolved.** Which "logged in" they meant is
still unknown — GitHub/releases, the running Godot game + RCON, or the
CCC fleet. Three options were offered and the answer was a re-park.
**If they ask again, ask which one they mean rather than re-answering
GitHub.**

**Inherited from MSG-PROJ-001 — the original request, verbatim:**
> "make a way that i can modle things i want to make like the grabers
> pincer kinda things"

Note **"like the grabers pincer"** — the claw is the *example*, not the
whole ask. That is why STO-TOOLS-017 (any part, not just claws) exists.

**Their choice of approach, and why it matters.** Three options were
offered: an in-game workshop (drag blocks with the mouse), a
live-reloading numbers file, and Godot's own editor. **They chose Godot's
own editor** — the boldest, and the one whose listed cost was "a lot of
program" for a young operator. That choice is load-bearing:
- It is why STO-TOOLS-011 **exports their existing claw into the file**
  rather than creating a blank one. A blank page would kill this.
- It is why STO-TOOLS-013 (plain-words errors) was built *with* 011
  instead of later — the argument was that they would almost certainly
  rename something on day one, and they agreed: **"yes build 011 and
  013"**.
- The in-game workshop stays written down as the fallback if the editor
  proves too much. The file format already built is what it would have
  saved to anyway, so nothing is wasted.

**Standing meta-requirement, unchanged and non-negotiable:** every
feature is captured in `effort/` (design -> epic -> story) and read back
to the operator for a "yes" BEFORE it is built. Failed attempts are kept,
not deleted. Reversals get recorded rather than rewritten.

**Nothing is deferred for a hidden reason.** 012/014/015/016/017 are
unstarted simply because 011+013 shipped first by explicit instruction.

## Key Context

**Three mistakes from the 011/013 session, recorded in the story files
and commit messages — do not let a successor rediscover them as new:**

1. Used `class_name PartModel`. Global class names do NOT resolve under
   `godot -s`; everything depending on it loaded scriptless. delve's
   convention is `const X := preload(...)` everywhere, for exactly this
   reason. Cost a full test run. Already in agent memory
   (`godot-headless-testing.md`).
2. **A confident comment that could not be backed up.** It claimed
   `CACHE_MODE_REPLACE` was necessary; sabotage-testing it twice passed
   BOTH times, so the reasoning was wrong. Code kept as cheap insurance,
   comment rewritten to say plainly it is not a demonstrated fix. **Do
   not let that comment drift back into a confident claim.**
3. First `arm_scale` check measured the prong TIP, which moves with the
   curl — reported 2.118 for a claw that is exactly 2x. Measuring the
   prong ROOT (above the curl joint) gives exactly 2.000. Recurring class
   of error: **measured the pose, not the thing.**

**A descope made in writing rather than quietly:** the collision walk was
planned for STO-TOOLS-012 but shipped in 011, because once the `Touch`
areas are absent from the exported file, *something* must create them,
and a throwaway would have meant two mechanisms for one job.
STO-TOOLS-012 is amended in writing — what remains is the *guarantees*
(prove a hand-added block becomes solid), not the mechanism.

**Verification state, so nobody re-runs it blind:**
- `smoke_claw` passes **UNCHANGED**, byte-identical measurements (spread
  0.496x0.304, elbow 0.1001, blocks 0.231/0.429, 16 pieces). That was the
  safety net for the whole refactor.
- `smoke_part_model` (new) proves the game FOLLOWS the file
  (0.231 -> 0.7371 m) and that a broken model is survivable.
- Sabotage-tested 4 ways: ignoring the file fails 7 checks, dropping the
  fallback fails 8, ignoring `arm_scale` fails the ratio.
- **Full suite: 89 pass / 10 fail. All 10 fail IDENTICALLY before the
  change** — baselined via `git stash`. `smoke_arms` and
  `smoke_held_by_leg` are FLAKY, not fixed; do not claim credit.

**Still open from earlier sessions (unchanged):** STO-UI-010 (reconnect
without disturbing the host) — asked for twice, never started; its
written hard part is that a returning player gets a new peer id.
STO-CHARACTER-085's grip-slipping is still unimplemented.

**Known trap:** three tests (`smoke_abilities`, `smoke_grab`,
`smoke_rmb_pickup`) call functions directly and would pass with every
control disconnected.

## Active Files

Nothing was edited this session. Files still in play from 011/013:

- `scripts/part_model.gd` — loader, validator, collision walk
- `tools/export_part.gd` — packs code-built parts into a scene
- `scenes/parts/claw.tscn` + `claw_default.tscn` — the model and its
  never-edited spare
- `tests/smoke_part_model.gd`
- `scripts/mechanical_arms.gd` — 8 constants + `_make_prong()` deleted
- `effort/tools/epic-modelling/` — epic + 7 stories
- `.claude/agent-memory/ember/godot-headless-testing.md`
- `.claude/agent-memory/ember/ccc-park-host-paths.md` — the park-path
  workaround, saved as memory at `5ef8a16` so a fourth session does not
  re-measure it

All committed and pushed. Working tree clean at park.

## Environment note — the `/park` resolver bug, hit a THIRD time

`/park` step 0's resolver anchors on `scripts/` + `.beads/`. This host's
CCC checkout is `/home/dax/ccc/workspace`, which has `scripts/` and
`.ccc/` but **no `.beads/`** — so the resolver refuses with
`FATAL: no CCC checkout above this skill`. CCC is present the whole time;
all three helpers exist at `/home/dax/ccc/workspace/scripts/`
(`ccc_beads_first.py`, `ccc_legacy_handoff.py`, `delegate_parked.py`).

This session read the workaround out of agent memory instead of
re-measuring, which is what that memory is for — but it still means the
skill remains wrong on this host.

Also on this host:
- `ccc_beads_first.py --self-test` fails its third case, because it
  hardcodes `/var/ccc/workspace` — the PRIMARY's path, absent on this
  node. The predicate itself is correct; only the self-test is wrong.
  Same shape as STO-BUGS-135, one host over.
- The skill's step-4a snippet says `bin/ccc-bd`, which is **relative to
  the CCC workspace, not the project** — it fails from delve's cwd. Use
  `ccc-bd` on PATH (`/home/dax/.local/bin/ccc-bd`). Same for the
  `bin/ccc-bd close` in step 6.

**This has now cost three parks. File it upstream** (`/ccc-bug`).
**WHY-DEFERRED, again:** this session was a bare park with zero operator
mandate and zero turns of its own; filing a platform bug is not parking.
A successor with a spare moment should just file it — the measurements
are all in `.claude/agent-memory/ember/ccc-park-host-paths.md`, so it is
a five-minute job with nothing left to discover.

## Beads XIDs

- `MSG-PROJ-002` — **closed by this park as superseded** (STO-BUGS-138).
  Its content is carried forward above in full; nothing in it was
  resumed. (It had itself superseded `MSG-PROJ-001`.)
- `EPI-TOOLS-MODELLING` — in_progress; 2 of 7 stories done
- `STO-TOOLS-011` — **in_progress, deliberately not closed**; every
  checkbox ticked except the operator-only one (does it look right in the
  editor?)
- `STO-TOOLS-013` — closed/shipped
- `STO-TOOLS-012` — open, amended smaller (mechanism already shipped)
- `STO-TOOLS-014/015/016/017` — open, unstarted
- `STO-TOOLS-009` — open (tests can run while the game is open)
- `DES-TOOLS-001` — in_progress (TUMU testing & diagnostics infra)
- `EPI-TOOLS-RCON-DEBUG` — open
- `STO-UI-002` — in_progress, flagged stale-in-progress (pre-existing)
- Nothing was assigned to `ember` and in-progress at park time
  (`ccc-bd list --assignee=ember --status=in-progress` returned empty).

## Status notes

- 2026-08-26: Filed.
