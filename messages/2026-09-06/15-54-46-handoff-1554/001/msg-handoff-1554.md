---
xid: MSG-PROJ-005
content-path: /home/dax/projects/delve/messages/2026-09-06/15-54-46-handoff-1554/001/msg-handoff-1554.md
kind: msg
effort: proj
status: open
date: 2026-09-06
to: ember
from: ember
topic: handoff-1554
bd-id: delve-db1l
---

# Handoff from previous ember session

> **FIFTH consecutive park with no work.** But this one differs from the
> last three in a way that matters: **the operator was present.** A real
> `/go` ran, MSG-PROJ-004 was resumed and consumed, the operator was asked
> a direct question — and answered with `/park --exit` instead of
> answering it. That is new information, not another empty relay. Read
> "What Was Happening" before assuming this is more of the same.

## What Was Happening

This session did exactly two things: `/go`, then `/park --exit`.

The `/go` was a **real resume**, not a NOOP:
- MSG-PROJ-004 was found, read in full, and **closed** (consumed).
- Its claims were **re-verified against live state** rather than trusted.
- The parked marker was cleared, then re-set by this park.

Every inherited claim was checked and **all of it held**:
- Working tree clean at `b6cf1db` on `main`. Nothing built, edited, or
  decided since 2026-08-26.
- **No Godot process running** (`pgrep -af godot` -> nothing).
- **RCON 9999 not answering.** No live game, no editor.
- Beads statuses match the handoff exactly — nothing moved in ~11 days.

**Then the operator was asked the #1 question** (see below) and replied
`/park --exit`.

## What Needs to Happen Next

1. **Ask about `claw.tscn` again — but ask it DIFFERENTLY.** The last four
   handoffs all said "ask them what they see." This session finally *did*
   ask, with the editor-relaunch offer attached, and got a park instead of
   an answer. **So the question, as phrased, is not landing.** Do not
   simply re-ask it a sixth time verbatim.
   **WHY-DEFERRED (five times):** still not a block and still not
   laziness — STO-TOOLS-011's final DoD checkbox is *"Opening `claw.tscn`
   in Godot shows a claw, not an empty scene"*, which is **operator-only**
   by construction. `ccc-bd` correctly refuses to close the story. What is
   new is that "nobody was at the keyboard" is **no longer the
   explanation** — someone was, and parked anyway.
   **Successor: consider that the ask may be too big.** It requires them
   to sit down at a launched editor and evaluate something. A smaller
   opening ("want to see the claw?") may work better than a
   verification-shaped request.
2. Then either **STO-TOOLS-015** (the guide) or **STO-TOOLS-017** (same
   trick for spike + spider legs). Offered three sessions ago; **they
   picked neither.** Still do not pick for them.
3. **File the `/park` resolver bug upstream** (`/ccc-bug`). See the
   reversal note below — this session committed to doing it and then
   could not.

## Operator's Words / Open Decisions

**This session, verbatim — the complete operator content of it:**
> `/go`

> `/park --exit`

That is all. Two slash commands, no prose.

**What they were asked, in between, and did not answer.** This matters
more than the empty input, so it is recorded in full rather than
summarized. They were told the live state (no Godot running, tree clean,
nothing moved), given the Beads status table, and then asked:

> "So, first thing: **want me to launch the Godot editor so you can look
> at the claw?** If it shows a claw you can drag around, that story is
> done and we close it properly."

They were also re-offered STO-TOOLS-015 and STO-TOOLS-017 *without* a
recommendation between them, and reminded that their old "Are we logged
in?" question was still unanswered pending which sense they meant.

**The response to all of that was `/park --exit`.** No selection, no
"later", no question. **Do not read this as a refusal** — read it as the
same signal as the last four parks: the session ends without engagement.
Five for five now.

**A REVERSAL, recorded rather than rewritten (standing requirement).**
This session told the operator, in writing:
> "One housekeeping item I'll take care of myself, since this session
> isn't a bare park: filing the `/park` resolver bug upstream."

It then **did not file it**, because the very next input was
`/park --exit`, which turned the session into a bare park after all and
re-armed the carve-out. The commitment was sincere when made and was
invalidated by the operator's next input, not abandoned. **Successor: the
promise is outstanding and the operator has seen it made.**

**From MSG-PROJ-002, verbatim — still unresolved:**
> "Are we logged in?"

Re-surfaced this session; still not answered, because which "logged in"
is still unknown — GitHub/releases, the running Godot game + RCON, or the
CCC fleet. Already established and not to be re-derived: session is tmux
`delve-ember`; **`gh` is not installed on this host**, so there is no
GitHub CLI login to check; remote is `git@github.com:daxprz/delve.git` —
**SSH**, so pushes authenticate by key, not a login. **If they ask again,
ask which one they mean rather than re-answering GitHub.**

**Inherited from MSG-PROJ-001 — the original request, verbatim:**
> "make a way that i can modle things i want to make like the grabers
> pincer kinda things"

Note **"like the grabers pincer"** — the claw is the *example*, not the
whole ask. That is why STO-TOOLS-017 (any part, not just claws) exists.

**Their choice of approach, and why it is load-bearing.** Three options
were offered: an in-game workshop (drag blocks with the mouse), a
live-reloading numbers file, and Godot's own editor. **They chose Godot's
own editor** — the boldest, and the one whose listed cost was "a lot of
program" for a young operator.
- It is why STO-TOOLS-011 **exports their existing claw into the file**
  rather than creating a blank one. A blank page would kill this.
- It is why STO-TOOLS-013 (plain-words errors) shipped *with* 011 instead
  of later — the argument was they would rename something on day one, and
  they agreed: **"yes build 011 and 013"**.
- The in-game workshop stays written down as the fallback if the editor
  proves too much. The file format already built is what it would have
  saved to anyway, so nothing is wasted.
  **Five silent parks in, a successor should hold this fallback in mind**
  — not act on it unasked, but it exists for exactly this shape of
  evidence.

**Standing meta-requirement, unchanged and non-negotiable:** every
feature is captured in `effort/` (design -> epic -> story) and read back
to the operator for a "yes" BEFORE it is built. Failed attempts are kept,
not deleted. Reversals get recorded rather than rewritten (see above for
this session's).

**Nothing is deferred for a hidden reason.** 012/014/015/016/017 are
unstarted simply because 011+013 shipped first by explicit instruction.

## Key Context

**Three mistakes from the 011/013 session — recorded in the story files
and commit messages. Do not let a successor rediscover them as new:**

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

**Verification state — do not re-run blind, and do not restate as fresh:**
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
- **These numbers are ~11 days old.** True at `b33f4ae`; the tree has not
  changed since (verified clean this session), so they should still hold
  — but say **"last measured 2026-08-26"**, never "passes".

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
  workaround; **read it instead of re-measuring** (this session did, and
  it was correct on both counts)

## Environment note — the `/park` resolver bug, hit a FIFTH time

`/park` step 0's resolver anchors on a directory having BOTH `scripts/`
and `.beads/`. This host's CCC checkout is `/home/dax/ccc/workspace`,
which has `scripts/` and `.ccc/` but **no `.beads/`** — so it refuses
with `FATAL: no CCC checkout above this skill`. CCC is present the whole
time; all helpers exist at `/home/dax/ccc/workspace/scripts/`.

This session read the workaround from agent memory instead of
re-measuring — which is what that memory is for — and **re-verified both
claims**: the helpers exist, and `ccc_beads_first.py` reports
`beads-first` for delve via `.beads/redirect`.

Also on this host (both re-confirmed this session):
- `ccc_beads_first.py --self-test` fails its third case because it
  hardcodes `/var/ccc/workspace` — the PRIMARY's path, absent on this
  node. The predicate itself is correct; only the self-test is wrong.
  Same shape as STO-BUGS-135, one host over.
- The skill's step-4a snippet says `bin/ccc-bd`, which is **relative to
  the CCC workspace, not the project** — it fails from delve's cwd. Use
  `ccc-bd` on PATH (`/home/dax/.local/bin/ccc-bd`). Same for step 6's
  `close` and `/go`'s step-4 guard.

**WHY-DEFERRED — now with a recorded broken promise attached.** Five
sessions have declined for the same defensible reason: `--exit` means an
automated caller is waiting on this process to disappear, and filing a
platform bug is not parking. MSG-PROJ-004 carved out "file it FIRST in
any session that is not itself a bare park" — and this session **was**
bare, so the carve-out fired again. But this session also *told the
operator it would file it*, which is a new cost the previous four did not
carry. Every measurement needed is in the memory file; there is nothing
left to discover. **Successor: the first non-bare session files this
before anything else.**

## Beads XIDs

All statuses below were read live from `ccc-bd show` this session, not
copied from the prior handoff.

- `MSG-PROJ-004` — **closed by this session's `/go`** (consumed on
  resume, per /go step 4). Its content is carried forward above in full.
  It superseded 003, which superseded 002, which superseded 001.
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
  untouched
- `STO-UI-002` — in_progress, flagged stale-in-progress (pre-existing)
- Nothing assigned to `ember` and in-progress at park time
  (`ccc-bd list --assignee=ember --status=in-progress` returned empty —
  re-run and confirmed this session).

## Status notes

- 2026-09-06: Filed.
