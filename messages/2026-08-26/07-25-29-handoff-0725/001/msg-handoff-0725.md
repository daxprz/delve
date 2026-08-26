---
xid: MSG-PROJ-001
content-path: /home/dax/projects/delve/messages/2026-08-26/07-25-29-handoff-0725/001/msg-handoff-0725.md
kind: msg
effort: proj
status: open
date: 2026-08-26
to: ember
from: ember
topic: handoff-0725
bd-id: delve-p9o3
---

# Handoff from previous ember session

## What Was Happening

Building **EPI-TOOLS-MODELLING** — a way for the operator (a child) to
model game shapes in Godot's editor instead of describing them to an
agent in words.

**STO-TOOLS-011 and STO-TOOLS-013 shipped** (commits `b33f4ae`,
`a6faea9`, pushed to `main`). The claw's shape moved out of eight
constants in `mechanical_arms.gd` and into `scenes/parts/claw.tscn`,
which the operator can drag around in Godot.

**Immediately before parking, I launched the Godot editor for them**
(`nohup godot --editor --path . > /tmp/godot_editor.log`, pid 4049116,
Vulkan up on the RTX 4080) and told them where to find `claw.tscn` and
what to try first. **They have not yet reported back what they saw.**
That is the open thread.

## What Needs to Happen Next

1. **Ask what they saw in the editor.** The last DoD checkbox on
   STO-TOOLS-011 is operator-only — *"Opening `claw.tscn` in Godot shows
   a claw, not an empty scene"* — and nobody has looked. STO-TOOLS-011
   is deliberately still `in-progress`, not shipped, because of it.
   `ccc-bd` correctly refused to close it.
2. Then either **STO-TOOLS-015** (the guide, so the instructions live
   somewhere findable) or **STO-TOOLS-017** (same trick for the spike
   and spider legs) — I offered both; they picked neither yet.

## Operator's Words / Open Decisions

**The request, verbatim:**
> "make a way that i can modle things i want to make like the grabers
> pincer kinda things"

Note **"like the grabers pincer"** — the claw is the *example*, not the
whole ask. That is why STO-TOOLS-017 (any part, not just claws) exists.

**Their choice of approach, and why it matters.** I offered three
options via AskUserQuestion: an in-game workshop (drag blocks with the
mouse), a live-reloading numbers file, and Godot's own editor. **They
chose Godot's own editor** — the boldest option, and the one whose
listed cost was "a lot of program" for a young operator.

That choice is load-bearing for everything downstream:
- It is why STO-TOOLS-011 **exports their existing claw into the file**
  rather than creating a blank one. A blank page would kill this.
- It is why STO-TOOLS-013 (plain-words errors) was built *with* 011
  instead of later — I argued they would almost certainly rename
  something on day one, and they agreed by saying **"yes build 011 and
  013"**.
- The in-game workshop stays written down as the fallback if the editor
  proves too much. The file format built here is what it would have
  saved to anyway, so nothing is wasted.

**Standing meta-requirement, unchanged and non-negotiable:** every
feature is captured in `effort/` (design -> epic -> story) and read back
to the operator for a "yes" BEFORE it is built. Failed attempts are kept,
not deleted. Reversals get recorded rather than rewritten.

**Nothing is deferred for a hidden reason.** 012/014/015/016/017 are
unstarted simply because we shipped 011+013 first by their explicit
instruction.

## Key Context

**Three things I got wrong this session, all recorded in the story
files and the commit message — do not let a successor rediscover them
as if they were new:**

1. Used `class_name PartModel`. Global class names do NOT resolve under
   `godot -s`; everything depending on it loaded scriptless. delve's
   convention is `const X := preload(...)` everywhere, for exactly this
   reason. Cost a full test run. **Saved to agent memory.**
2. **Wrote a confident comment I could not back up.** Claimed
   `CACHE_MODE_REPLACE` was necessary; sabotage-tested it twice and the
   test passed BOTH times, so the reasoning was wrong. Kept the code as
   cheap insurance but rewrote the comment to say plainly it is not a
   demonstrated fix. The story says so too. **Do not let that comment
   drift back into a confident claim.**
3. First `arm_scale` check measured the prong TIP, which moves with the
   curl — reported 2.118 for a claw that is exactly 2x. Measuring the
   prong ROOT (above the curl joint) gives exactly 2.000. Same class of
   error as several past ones: **measured the pose, not the thing.**

**A descope I made and wrote down rather than doing quietly:** the
collision walk was planned for STO-TOOLS-012 but shipped in 011, because
once the `Touch` areas are absent from the exported file, *something*
must create them, and a throwaway version would have meant two
mechanisms for one job. STO-TOOLS-012 is amended in writing — what
remains is the *guarantees* (prove a hand-added block becomes solid),
not the mechanism.

**Verification state, so nobody re-runs it blind:**
- `smoke_claw` passes **UNCHANGED** with byte-identical measurements
  (spread 0.496x0.304, elbow 0.1001, blocks 0.231/0.429, 16 pieces).
  That was the safety net for the whole refactor.
- `smoke_part_model` (new) proves the game FOLLOWS the file
  (0.231 -> 0.7371 m) and that a broken model is survivable.
- Sabotage-tested 4 ways: ignoring the file fails 7 checks, dropping the
  fallback fails 8, ignoring `arm_scale` fails the ratio.
- **Full suite: 89 pass / 10 fail. All 10 fail IDENTICALLY before this
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

- `scripts/part_model.gd` (new) — loader, validator, collision walk
- `tools/export_part.gd` (new) — packs code-built parts into a scene
- `scenes/parts/claw.tscn` + `claw_default.tscn` (new) — the model and
  its never-edited spare
- `tests/smoke_part_model.gd` (new)
- `scripts/mechanical_arms.gd` — 8 constants + `_make_prong()` deleted
- `effort/tools/epic-modelling/` — epic + 7 stories
- `.claude/agent-memory/ember/godot-headless-testing.md` — added 8d, 8e

All committed and pushed. Working tree was clean at park.

## Environment note (not delve's problem, but it bit this park)

`/park` step 0's resolver anchors on `scripts/` + `.beads/`. This host's
CCC checkout is `/home/dax/ccc/workspace`, which has `scripts/` and
`.ccc/` but **no `.beads/`** — so the resolver refused. CCC was present
the whole time; all three helpers exist at
`/home/dax/ccc/workspace/scripts/`. I verified that by measurement and
proceeded, rather than falling through to the legacy branch (which is
the documented bug). `ccc_beads_first.py --self-test` also fails its
third case here, because it hardcodes `/var/ccc/workspace` — the
PRIMARY's path, absent on this node. Same shape as STO-BUGS-135, one
host over. **Worth filing upstream.**

## Beads XIDs

- `EPI-TOOLS-MODELLING` — in-progress; 2 of 7 stories done
- `STO-TOOLS-011` — **in-progress, deliberately not closed**; every
  checkbox ticked except the operator-only one (does it look right in
  the editor?)
- `STO-TOOLS-013` — closed/shipped
- `STO-TOOLS-012` — open, amended smaller (mechanism already shipped)
- `STO-TOOLS-014/015/016/017` — open, unstarted
- `STO-UI-002` — in-progress, flagged stale-in-progress (pre-existing)

## Status notes

- 2026-08-26: Filed.
