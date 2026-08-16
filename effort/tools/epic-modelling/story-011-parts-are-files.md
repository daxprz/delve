---
xid: STO-TOOLS-011
parent: ./epic.md
kind: story
effort: tools
size: S
status: in-progress
date: 2026-08-16
depends-on: []
bd-id: delve-utm3
---

# Parts live in files you can drag, not numbers in code

## Summary

The bridge story. Makes the claw's shape a **file** instead of eight
constants, so Godot's editor can edit it.

Two halves, and the order is the point:

**1. Export what already exists.** Before anything loads from a file,
generate `scenes/parts/claw.tscn` *from the current code*, so the file
contains the exact claw the operator already specified across four
rounds. Nothing on screen changes. This is the anti-blank-page half —
the first time the operator opens Godot they see **their own claw**,
already built, ready to be grabbed and pulled.

**2. Load it back.** `_add_prongs()` stops building boxes from
constants and instead instantiates that scene, scales it by
`arm_scale`, and names the root `Fingers` (the name everything else
looks for — the curl driver, the wrap, and the tests all reach for it,
so renaming it to something prettier would break four things for the
sake of a word).

These eight constants are deleted by this story:

```
PRONG_HUB_X  PRONG_HUB_Y  PRONG_FLARE  PRONG_KINK
PRONG_SEGMENTS  PRONG_BASE_SHARE  PRONG_LEN_MUL  PRONG_TH_MUL
```

Each one was a thing the operator had to describe in words. In the
editor they become dragging.

## The test that decides this

`smoke_claw` must pass **unchanged**.

It already checks four prongs, four corners, two blocks each, base
shorter than top, same section, slim, bent like `<`, 16 collidable
pieces, and the wider-across-than-up ratio — all by inspecting the
*resulting node tree*, never the constants. So it cannot tell where
the shape came from, which makes it the perfect guard for this switch.

**If `smoke_claw` needs editing to pass, the export changed the shape.
That is a bug in the export, not a chore.** Writing this down because
the tempting move when a test fails during a refactor is to adjust the
test, and here that would silently throw away four rounds of the
operator's decisions.

A second check is needed that the first cannot give: proof the game is
**really reading the file** and not just still building the same shape
in code. A test that only checks "the claw looks right" would pass if
the loading half were never wired up at all. So: change something in
the scene file, and assert the game changed with it.

## Definition of Done

- [x] `scenes/parts/claw.tscn` exists and contains the current claw.
- [x] `_add_prongs()` loads it; the eight shape constants are gone
      from `mechanical_arms.gd`.
- [x] `arm_scale` still works — a bigger Grabber gets a bigger claw.
- [x] `smoke_claw` passes **unchanged**.
- [x] A test proves the game follows the *file*: edit the scene, and
      the claw in the game differs.
- [ ] Opening `scenes/parts/claw.tscn` in Godot shows a claw, not an
      empty scene. **Only the operator can tick this** — the file is
      verified to load and to contain four prongs, but nobody has yet
      looked at it in the editor.

## Out of scope

- Automatic collision on newly added blocks — STO-TOOLS-012. This
  story keeps building the `Touch` areas in code exactly as now, so
  the export is a pure move with no behaviour change.
- Error messages for a broken model — STO-TOOLS-013.
- Any part other than the claw — STO-TOOLS-017.

## What shipped

`scenes/parts/claw.tscn` (29 nodes: 4 prongs x J0/Seg/End/J1/Seg/End),
with `claw_default.tscn` beside it as the never-edited copy.
`scripts/part_model.gd` loads and validates. `tools/export_part.gd`
generated the scene by packing what the real game code built, so the
file is the claw rather than a second description of it.

Deleted from `mechanical_arms.gd`: `PRONG_HUB_X`, `PRONG_HUB_Y`,
`PRONG_FLARE`, `PRONG_KINK`, `PRONG_SEGMENTS`, `PRONG_BASE_SHARE`,
`PRONG_LEN_MUL`, `PRONG_TH_MUL`, and `_make_prong()` — about 100 lines.

## Verification

`smoke_claw` passes **unchanged**, and every measurement is identical
to the pre-switch run:

| | before | after |
|---|---|---|
| prong spread | 0.496 x 0.304 | 0.496 x 0.304 |
| elbow off the line | 0.1001 m | 0.1001 m |
| block lengths | 0.231 / 0.429 | 0.231 / 0.429 |
| section | 0.0558 | 0.0558 |
| collidable pieces | 16 | 16 |

The shape moved into a file without moving.

`smoke_part_model` adds what `smoke_claw` structurally cannot: it
edits the file and checks the game changed (0.231 m -> 0.7371 m, a
length no constant produces), and checks every prong sits where the
file puts it (0.000000 m out).

Sabotage-tested. Making the loader ignore the operator's file fails 7
checks; ignoring `arm_scale` fails the size ratio (2.000 -> 1.000).

Full suite: 89 pass, 10 fail — **all 10 failing identically before
this change** (`smoke_arms`, `smoke_grip_sticks`, `smoke_ragdoll`,
`smoke_rcon`, `smoke_tail`, and the four `mp_`/`name_` tests that need
a second process). `smoke_held_by_leg` failed once in the suite and
passes 3/3 alone — pre-existing flakiness, not caused or fixed here.

## Amendment: the collision walk arrived early

The story planned to keep building the `Touch` areas in code exactly
as before, leaving generated collision to STO-TOOLS-012. That turned
out not to be separable.

The exported scene deliberately does NOT contain the collision areas —
including them would have doubled the node count the operator sees in
the editor (12 per prong instead of 6) and meant hand-adding a
collider to every new block. But once they are not in the file,
something has to create them, and that something is the generated
walk. Writing a temporary version first and replacing it in the next
story would have been two mechanisms for one job.

So `PartModel.add_collision()` shipped here. STO-TOOLS-012 is
correspondingly smaller than written — its remaining work is the
guarantees, not the mechanism: proving a hand-added block becomes
solid, and respecting hand-authored collision. Recorded rather than
quietly re-scoped.
