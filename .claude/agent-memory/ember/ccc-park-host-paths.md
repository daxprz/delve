---
name: ccc-park-host-paths
description: On this host the /park skill's step-0 resolver refuses and its `bin/ccc-bd` snippets fail; here are the measured-correct paths.
metadata:
  type: project
---

On this host (`dax@`, delve), `/park`'s own documented snippets do not
run as written. Measured, twice (2026-08-26, MSG-PROJ-001 and
MSG-PROJ-002).

- **Step 0 resolver refuses.** It anchors on a dir having BOTH `scripts/`
  and `.beads/`. This host's CCC checkout is `/home/dax/ccc/workspace`,
  which has `scripts/` and `.ccc/` but **no `.beads/`** — so it exits
  `FATAL: no CCC checkout above this skill`. CCC is fully present.
  Correct value: `CCC_SCRIPTS=/home/dax/ccc/workspace/scripts` — verified
  by confirming `ccc_beads_first.py`, `ccc_legacy_handoff.py`, and
  `delegate_parked.py` all exist there.
- **`bin/ccc-bd` is relative to the CCC workspace, not the project.** It
  fails from a project cwd. Use `ccc-bd` on PATH
  (`/home/dax/.local/bin/ccc-bd`). Applies to step 4a's mint and step 6's
  close.
- `ccc_beads_first.py --self-test` fails its third case here because it
  hardcodes `/var/ccc/workspace` (the PRIMARY's path, absent on this
  node). The predicate itself works correctly — only the self-test is
  wrong.
- delve IS Beads-first (`.beads/redirect` resolves); always take branch
  4a. Handoffs are tracked in git and each park commits its own.

**Why:** the resolver's refusal is deliberate — falling through to the
legacy branch is the documented bug (STO-BUGS-091/135). So the right
move is to identify the scripts dir by measurement and proceed, NOT to
degrade to legacy.

**How to apply:** when running `/park` (or any skill using
`$CCC_SCRIPTS`) here, skip the step-0 heredoc and use the paths above
after confirming the three helpers exist. Not yet filed upstream — worth
a `/ccc-bug`. See [[godot-headless-testing]].
