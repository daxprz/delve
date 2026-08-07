---
xid: STO-CORE-007
parent: ./epic.md
kind: story
effort: core
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-2vg
shipped: 2026-08-07
tasks: 4
complete: 4
---

# A joining player always lands on its spawn slot

## Summary

When you join a game, your player should appear on its slot in the
spawn ring (STO-CORE-004). Sometimes it appears at the world origin
instead.

A player places itself in `player.gd _ready()` by asking the main
scene for its slot — but it finds the main scene through
`get_tree().current_scene`. When that is null, the whole placement is
skipped **silently**, and the player is left wherever it happened to
start. There is no error; it just quietly does the wrong thing.

Whether it works then depends on the spawn state arriving over the
network first, which is a race: it usually wins, and about **one join
in six** it does not.

## How it was found

Not by looking at the code. STO-UI-006 added connect-time network
traffic, which shifted the timing enough to make the existing
two-instance test flake. Chasing that turned up a *second* problem:
the test read its "starting position" the instant the player node
appeared — before any position had arrived — so it was measuring from
(0, 0, 0). Walking forward looked like walking backwards.

Fixing the test to wait for a real position is what finally made this
bug visible. Measured with the fix in place:

| code | result |
|---|---|
| STO-UI-006 branch | 10 pass / 2 fail in 12 |
| **`main` without any of it** | **10 pass / 2 fail in 12** |

The same rate on untouched `main`, so this is old, not new. The old
test could never have caught it: it measured from the origin, so a
player that really was at the origin still looked fine.

## Definition of Done

- [x] A player finds its spawn slot without depending on
      `get_tree().current_scene` — it walks up its own ancestors
      instead.
- [x] If it genuinely cannot find one, that is reported rather than
      silently skipped.
- [x] The placement no longer depends on the network at all: the
      owning peer sets its own position in `_ready`, before any spawn
      state has to arrive.
- [x] The fix is shown to have teeth by reverting it.

## Out of scope

- Choosing spawn points to avoid geometry, or any change to which
  slot a peer gets — only that it reliably arrives at the one it was
  already assigned.

## Verification notes (2026-08-07)

**Counting passing runs turned out to be the wrong instrument.** The
first attempt measured 12/12 with the fix and concluded it worked —
then the teeth check (fix disabled) *also* scored 12/12. A rare race
plus a loaded machine makes run-counts noise, and two of my earlier
comparisons were reading that noise as signal.

The honest measurement is direct, and gives the same answer every
time:

| | what the joining client reports |
|---|---|
| with the ancestor walk | `placed itself at (0.26, 1.00, 2.71) via Main` |
| with it disabled | `WARNING: no spawn owner found, staying at (0,0,0)` |

That is the whole bug in two lines, with no statistics involved.

The run-count DoD item was dropped rather than ticked: it cannot tell
the two versions apart, so passing it would have proved nothing.

## Notes

Two lessons worth keeping:

- **A lookup that silently does nothing on failure is worse than one
  that errors.** This hid for the project's whole life behind a test
  that measured from the wrong starting point.
- **Don't use pass-counts to judge a rare race.** If a fix and its
  absence score the same, the experiment is not measuring the fix.
  Find something deterministic to look at instead.
