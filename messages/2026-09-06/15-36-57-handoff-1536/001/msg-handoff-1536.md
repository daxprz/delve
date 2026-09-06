---
xid: MSG-PROJ-004
content-path: /home/dax/projects/delve/messages/2026-09-06/15-36-57-handoff-1536/001/msg-handoff-1536.md
kind: msg
effort: proj
status: open
date: 2026-09-06
to: ember
from: ember
topic: handoff-1536
bd-id: delve-75b4
---

# Handoff from previous ember session

> **FOURTH consecutive park with no work and no operator contact.** This
> session was spawned and handed `/park --exit` as its first and only
> input. Its whole job is to carry MSG-PROJ-003 forward, which carried
> 002, which carried 001. Everything below is inherited and still live —
> read it as the current state of the project, not as history.
>
> **One thing DID change, and it matters:** ~11 days of wall clock passed
> (2026-08-26 -> 2026-09-06) and **the Godot editor the last three
> handoffs told you to ask about is DEAD.** Corrected below. Do not
> repeat the stale claim.

## What Was Happening

**Nothing was built, read, tested, or decided.** No commits, no Beads
changes, no file edits. Working tree clean at `acde807` on `main`.

The inherited open thread, unchanged across all four handoffs:

Building **EPI-TOOLS-MODELLING** — a way for the operator (a child) to
model game shapes in Godot's editor instead of describing them in words.
**STO-TOOLS-011 and STO-TOOLS-013 shipped** (`b33f4ae`, `a6faea9`, on
`main`). The claw's shape moved out of eight constants in
`mechanical_arms.gd` into `scenes/parts/claw.tscn`, which the operator
can drag around in Godot.

A session four parks ago launched the Godot editor for them and asked
them to look at `claw.tscn`. **They still have not reported what they
saw** — and now they cannot, because the window is gone.

## Environment delta measured THIS session (supersedes MSG-PROJ-003)

Measured, not assumed:

- **Godot editor pid `4049116` is GONE.** MSG-PROJ-003 recorded it live
  at 1h13m; ~11 days later it is not in the process table.
- **No Godot process of any kind is running** (`pgrep -af godot` returns
  only the probing shell itself — do not misread that line as a hit).
- **RCON port 9999 is not answering** (`echo status | nc -w1` fails). So
  there is no live game to inspect either.

**Consequence for the successor:** you must **relaunch the editor before
asking the operator what they see** — `godot --editor --path .`, log to
`/tmp/godot_editor.log`. The previous three handoffs' "the editor is
still up, just ask them" shortcut no longer applies.

## What Needs to Happen Next

1. **Relaunch the editor, then ask what they see in `claw.tscn`.** This
   is the same #1 for the fourth time, but the first step is now new
   (see above). The last DoD checkbox on STO-TOOLS-011 is operator-only —
   *"Opening `claw.tscn` in Godot shows a claw, not an empty scene"* — and
   nobody has looked. STO-TOOLS-011 is deliberately still `in_progress`
   because of it; `ccc-bd` correctly refused to close it.
   **WHY-DEFERRED (four times now):** not a block and not laziness — it
   needs the operator's eyes, and they have not been at the keyboard.
   Three of the four intervening sessions had no operator present at all.
   Ask this before offering anything else.
2. Then either **STO-TOOLS-015** (the guide, so instructions live
   somewhere findable) or **STO-TOOLS-017** (same trick for the spike and
   spider legs). Both were offered three sessions ago; **they picked
   neither.** Do not pick for them.
3. **File the `/park` resolver bug upstream** (`/ccc-bug`). See below —
   it has now cost FOUR parks and the deferral reasoning has stopped
   being good.

## Operator's Words / Open Decisions

**This session, verbatim — the complete operator content of it:**
> `/park --exit`

That is all. No question, no instruction, nothing to interpret. There is
genuinely nothing new to hand on from this session; the value of this
artifact is the carried-forward context below plus the editor-is-dead
correction above.

**From MSG-PROJ-002, verbatim — still unresolved:**
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

**Which "logged in" they meant is still unknown** — GitHub/releases, the
running Godot game + RCON, or the CCC fleet. Three options were offered
and the answer was a re-park. **If they ask again, ask which one they
mean rather than re-answering GitHub.**

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
- **These numbers are now ~11 days old and nothing has re-run them.**
  They were true at `b33f4ae`; the tree has not changed since, so they
  should still hold — but say "last measured 2026-08-26", not "passes".

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
  workaround; read it instead of re-measuring

All committed and pushed. Working tree clean at park.

## Environment note — the `/park` resolver bug, hit a FOURTH time

`/park` step 0's resolver anchors on a directory having BOTH `scripts/`
and `.beads/`. This host's CCC checkout is `/home/dax/ccc/workspace`,
which has `scripts/` and `.ccc/` but **no `.beads/`** — so it refuses
with `FATAL: no CCC checkout above this skill`. CCC is present the whole
time; all three helpers exist at `/home/dax/ccc/workspace/scripts/`
(`ccc_beads_first.py`, `ccc_legacy_handoff.py`, `delegate_parked.py`).

This session read the workaround out of agent memory instead of
re-measuring — which is what that memory is for — and confirmed
`ccc_beads_first.py` still reports `beads-first` for delve.

Also on this host:
- `ccc_beads_first.py --self-test` fails its third case because it
  hardcodes `/var/ccc/workspace` — the PRIMARY's path, absent on this
  node. The predicate itself is correct; only the self-test is wrong.
  Same shape as STO-BUGS-135, one host over.
- The skill's step-4a snippet says `bin/ccc-bd`, which is **relative to
  the CCC workspace, not the project** — it fails from delve's cwd. Use
  `ccc-bd` on PATH (`/home/dax/.local/bin/ccc-bd`). Same for step 6's
  `close`.

**WHY-DEFERRED — and this reasoning is now wearing out.** Each of the
four sessions declined for the same defensible reason: `--exit` means an
automated caller is waiting on this process to disappear, and filing a
platform bug is not parking. That is still true. But four repetitions of
a "five-minute job" is the deferral pattern the skill warns about, and
the memory file holds every measurement needed, so there is nothing left
to discover. **Successor: file it FIRST, before anything else, in any
session that is not itself a bare park.**

## Beads XIDs

- `MSG-PROJ-003` — **closed by this park as superseded** (STO-BUGS-138).
  Its content is carried forward above in full and its editor claim is
  corrected; nothing in it was resumed. (It superseded 002, which
  superseded 001.)
- `EPI-TOOLS-MODELLING` — in_progress; 2 of 7 stories done
- `STO-TOOLS-011` — **in_progress, deliberately not closed**; every
  checkbox ticked except the operator-only one (does it look right in the
  editor?)
- `STO-TOOLS-013` — closed/shipped
- `STO-TOOLS-012` — open, amended smaller (mechanism already shipped)
- `STO-TOOLS-014/015/016/017` — open, unstarted
- `STO-TOOLS-009` — open (tests can run while the game is open)
- `DES-TOOLS-001` — in_progress (TUMU testing & diagnostics infra)
- `DES-CHARACTER-001`, `DES-UI-001`, `EPI-CHARACTER-RUNNER-TAIL`,
  `EPI-UI-PAUSE-MENU`, `STO-CHARACTER-052` — in_progress, pre-existing,
  untouched this session
- `STO-UI-002` — in_progress, flagged stale-in-progress (pre-existing)
- Nothing assigned to `ember` and in-progress at park time
  (`ccc-bd list --assignee=ember --status=in-progress` returned empty).

## Status notes

- 2026-09-06: Filed.
