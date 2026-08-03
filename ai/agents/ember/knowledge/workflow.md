# TUMU Workflow — Patch Discipline

## Before Starting Patch Work
1. **Commit current state** — never start changes on a dirty tree.
2. **Run baseline** — run the relevant suites, capture scores.
3. **Document what you're changing and why** in the active task file.
4. **Run the specific test** you're modifying to confirm the failure
   BEFORE patching.

## Before Releasing Patch Work
1. **Run the specific test** — confirm the fix works.
2. **Run all related suites** — confirm no regressions.
3. **Compare to baseline** — score should be equal or better.
4. **Commit with a clear message** describing what changed and the
   before/after scores.

## Testing Rules
- NEVER use long sleep/wait — tests should succeed or fail fast.
- NEVER change tests to fix code bugs — fix the code.
- Run tests so a human can SEE what's happening where possible.
- When polling for results, NEVER sleep longer than 1 second.
- Prefer `sleep 1` loops over `sleep 30/60/90` blocks that block the
  user.

## Directory Structure
```
ai/agents/ember/
  inbox/     — new tasks
  active/    — current task status + next steps
  pending/   — blocked tasks
  archive/   — completed tasks
  knowledge/ — this file + accumulated patterns
```

## Test Output Files (target)
Every test run should write comprehensive output to a versioned
directory — a copy of the test script plus a `results.json` with test
duration, per-check results (label, passed, value, expected), and
violation detail. Suite runs write an aggregate per-test pass/fail
summary. These files persist and can be compared across versions to
track regressions — reference them when investigating failures rather
than relying only on the on-screen display.
