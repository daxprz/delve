---
xid: MSG-PROJ-006
content-path: /home/dax/projects/delve/messages/2026-09-06/15-54-47-handoff-1554/001/msg-handoff-1554.md
kind: msg
effort: proj
status: open
date: 2026-09-06
to: ccc
from: ccc
topic: handoff-1554
bd-id: delve-28c8
---

# Handoff from previous ccc session

## What Was Happening

Fresh `ccc` (Sigma) delegate spawn on session `delve-ccc`. The operator
ran `/go`, which correctly **NOOPed** — `delegate_parked.py is delve-ccc`
returned rc 1 (`{"session": "delve-ccc", "parked": false}`), so there was
no park to resume. Nothing was read, nothing was mutated.

The only substantive output of the session was a **finding**, not work:
`/go`'s and `/park`'s step-0 `CCC_SCRIPTS` resolver **refuses on this
host**, for the third measured time.

## What Needs to Happen Next

1. **Decide the open `/ccc-bug`** (see Operator's Words below). I offered
   to file the step-0 resolver bug upstream; the operator parked before
   answering. If the answer is yes, file it — the write-up is essentially
   complete in Key Context below and in ember's memory file.
2. Otherwise nothing is in flight. `ccc-bd list --assignee=ccc
   --status=in-progress` returned an **empty** `data` array; there is no
   work parked mid-stream.

## Operator's Words / Open Decisions  **(MANDATORY)**

The operator typed exactly two things this session, both bare slash
commands with no prose:

- `/go`
- `/park --exit`

That is the complete verbatim record — there is no operator phrasing to
carry forward, and the next session should not infer intent that was
never stated.

**Open decision (UNANSWERED):** I ended my `/go` report with:

> "Per ember's memory this is now the third occurrence and still unfiled
> upstream — it's a genuine platform bug in the `park`/`go` skill's
> anchor predicate. Want me to `/ccc-bug` it?"

**WHY-DEFERRED:** the operator's next input was `/park --exit`, not an
answer. The question was never declined — it was overtaken. Do not read
the park as a "no". Re-ask it, or just file it; filing CCC-platform bugs
directly is this agent's own charter (STO-ONB-084), so the only reason it
is still open is that I asked instead of acting.

## Key Context

**The step-0 resolver bug, in full (so the next session need not
re-derive it):**

- Both `/go` and `/park` open with a resolver that walks up from the
  skill's realpath looking for a directory containing **both** `scripts/`
  **and** `.beads/`.
- This host's CCC checkout is `/home/dax/ccc/workspace`. It has
  `scripts/` and `.ccc/` but **no `.beads/`** — so the walk runs off the
  top and exits `FATAL: no CCC checkout above this skill`. CCC is fully
  and correctly installed; the *predicate* is wrong, not the host.
- The refusal is deliberate-by-design (falling through to the legacy
  branch is STO-BUGS-091/135), so the correct move is to measure the
  path and proceed — **never** to degrade to the legacy branch.
- Measured-correct values on this host, all re-verified this session:
  - `CCC_SCRIPTS=/home/dax/ccc/workspace/scripts` (confirmed
    `delegate_parked.py`, `ccc_beads_first.py`, `ccc_legacy_handoff.py`
    all present)
  - delegates dir = `/home/dax/ccc/delegates` (NOT `/var/ccc/delegates`)
  - `ccc-bd` = `/home/dax/.local/bin/ccc-bd` on PATH; **`bin/ccc-bd`
    fails from a project cwd** — it is relative to the CCC workspace
  - `ccc_beads_first.py` → rc 0, `.beads/redirect` found at
    `/home/dax/projects/delve`; delve is Beads-first, always branch 4a
- Prior art: `.claude/agent-memory/ember/ccc-park-host-paths.md`
  (commit `5ef8a16`), which records the same two failures and closes with
  "Not yet filed upstream — worth a `/ccc-bug`."

**Other observations:**

- `MSG-PROJ-005` is an **open** handoff addressed to `ember`, not to
  `ccc`. Correctly left untouched. `MSG-PROJ-001`..`004` are closed.
- This park's own marker had `handoff_xid: null` before minting (first
  park of this session), so nothing was superseded and no prior handoff
  needed closing.
- Minting note confirmed live: the positional effort is discarded for
  `msg` — I passed `core` and got `MSG-PROJ-006` / `effort: proj`, as the
  skill documents. Do not grep for `MSG-CORE-*` to verify a mint.

## Active Files

- `.claude/agent-memory/ember/ccc-park-host-paths.md` — read, not edited;
  the source of the measured paths above.
- `messages/2026-09-06/15-54-47-handoff-1554/001/msg-handoff-1554.md` —
  this file.

No source files were opened or edited this session.

## Beads XIDs

None. `ccc-bd list --assignee=ccc --status=in-progress --json` returned
an empty `data` array — this session held no Beads work.


## Status notes

- 2026-09-06: Filed.
