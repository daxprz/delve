---
xid: EPI-TOOLS-MODELLING
parent: ../design.md
kind: epic
effort: tools
status: in-progress
date: 2026-08-16
bd-id: delve-gcn2
---

# Model parts in the Godot editor instead of describing them

## Summary

**The operator wants to build shapes with their eyes instead of
describing them to an agent** (operator, 2026-08-16: *"make a way that
i can modle things i want to make like the grabers pincer kinda
things"*).

The request came directly out of the claw. Its shape was specified
across **four separate rounds**:

| Round | What the operator asked for |
|---|---|
| 1 | "make it so it acualy look like the claw" |
| 2 | "longer, shaped like `<`, four of them, one per corner" |
| 3 | "all point towards the middle, two blocks, base shorter, same width, slim, every piece collidable" |
| 4 | "all on the edges, pointing towards the middle, wider on the sides" |

Each round cost a code change, a test run and a guess. At no point
could the operator see the shape while describing it, and at no point
did they choose it directly — they described it and an agent
interpreted. **Four rounds and the operator still has not seen it.**

The cause is that shape currently lives as *numbers welded into a
script*. `mechanical_arms.gd` builds each prong from eight constants:

```gdscript
PRONG_HUB_X   PRONG_HUB_Y   PRONG_FLARE      PRONG_KINK
PRONG_SEGMENTS  PRONG_BASE_SHARE  PRONG_LEN_MUL  PRONG_TH_MUL
```

Nothing can model those. The whole epic is: **move shape out of code
and into a file the operator can drag around in Godot's own editor.**

## Why Godot's editor (operator's choice, 2026-08-16)

Three options were offered — an in-game workshop, a live-reloading
numbers file, and Godot's own editor. The operator chose the editor.

It is the right call for a reason worth writing down: it has **real
gizmos, real undo, a real 3D viewport, and costs nothing to build**.
delve does not have to grow a modelling program; it only has to *read
what the editor already saves*.

Its one genuine cost — Godot's editor is a large, complicated program
for a young operator — is answered in STO-TOOLS-011 and -015, not
waved away. See "The hard parts".

## The bridge that makes it possible

A prong the code builds is *already* a tree of named boxes:

```
ProngTL          planted at a corner, angled inward
└─ J0            base joint  (the curl driver rotates this on x)
   ├─ Seg        a box
   └─ End        where the base stops
      └─ J1      the elbow (kinked 38° on y)
         ├─ Seg  a longer box
         └─ End  the tip
```

That is exactly what a `.tscn` scene is. So the code does not need
rewriting — it needs to stop *inventing* that tree and start
*loading* it.

After the switch, the code's job shrinks to three things it is
actually good at, and gives up the one it is bad at:

| Code keeps | Code gives up |
|---|---|
| animating the curl | deciding the shape |
| scaling by `arm_scale` | |
| making pieces solid | |

## The hard parts

Named now so they are not discovered later.

1. **A blank page kills this.** If the operator opens Godot and finds
   an empty scene, the tool is abandoned in five minutes. So the first
   story does not create a blank file — it **exports the claw that
   already exists** into the scene, so the very first thing seen is
   their own claw, ready to grab. Editing beats starting.

2. **Collision by hand would be miserable.** Every block currently
   gets a `Touch` Area3D built in code. Hand-adding one per block in
   the editor is exactly the fiddly work that makes a tool not get
   used. The code must do it automatically (STO-TOOLS-012).

3. **The code finds parts by name.** Rename `J0` and the claw silently
   breaks. A silent break is the worst outcome for a young operator —
   it looks like "I did something wrong" with no way to find out what.
   So the loader must say, in plain words, what it could not find, and
   fall back to the code-built shape rather than vanishing
   (STO-TOOLS-013).

4. **`arm_scale` must still work.** A scene is one fixed size; the
   Grabber's arms scale. Answered by scaling the instantiated root
   rather than every constant.

5. **The existing claw tests must keep guarding it.** `smoke_claw`
   inspects the *resulting node tree*, not the constants — so it
   should still pass after the switch, unchanged. That is the safety
   net for this whole epic and it is worth stating as a requirement:
   **if the tests need editing to pass, the switch changed the shape,
   and that is a bug, not a chore.**

## Definition of Done

- [ ] The operator can open one file in Godot, drag a block, save, and
      see the claw change in the game — without an agent involved.
- [ ] The first time that file is opened, the claw they already
      designed is sitting in it, not a blank page.
- [ ] Blocks they add are solid without them adding collision.
- [ ] Getting it wrong prints a plain-words explanation, and the game
      still runs.
- [ ] `smoke_claw` passes **unchanged** across the switch.
- [ ] There is a written guide the operator can follow alone.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 011 | parts-are-files | S | The bridge: export the claw to a scene, load it back |
| 012 | auto-collision | M | Every block you add becomes solid by itself |
| 013 | says-whats-wrong | S | Plain-words errors, and never a vanished claw |
| 014 | blank-template | S | A part to copy when making something new |
| 015 | the-guide | S | How to do this alone, written for the operator |
| 016 | reload-without-restart | M | See the change without relaunching |
| 017 | any-part | M | Same rule for fists, legs, spikes — not just claws |

**Order matters.** 011 → 013 → 015 is the smallest set that is
genuinely usable alone: the file exists, it explains itself when
wrong, and there are instructions. 012 is what stops it being
annoying. 014, 016 and 017 are what make it a *tool* rather than a
one-off.

## Out of scope

- An in-game workshop with mouse-dragged blocks. Considered and not
  chosen (operator, 2026-08-16). If the editor turns out to be too
  much program, this is the fallback, and the file format built here
  is what it would have saved to anyway — so nothing is wasted.
- Modelling *behaviour*. This epic is about shape only. How a claw
  closes stays in code.
