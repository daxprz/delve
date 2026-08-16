---
xid: STO-TOOLS-017
parent: ./epic.md
kind: story
effort: tools
size: M
status: draft
date: 2026-08-16
depends-on: [STO-TOOLS-011, STO-TOOLS-012, STO-TOOLS-013]
bd-id: delve-hl07
---

# The same rule for any part, not just claws

## Summary

The operator asked for a way to model *"things i want to make like the
grabers pincer kinda things"* (2026-08-16) — **like** the pincers. The
claw is the example, not the whole ask.

This story turns the one-off into a rule:

> If `scenes/parts/<name>.tscn` exists, use it. If it does not, build
> it in code as now.

The fallback half is what makes this safe to apply widely. Every
procedural body in delve keeps working untouched; a part only becomes
editable when someone actually makes a file for it. Nothing has to be
converted, and nothing breaks by being left alone.

Candidates already sitting in code, all built from typed-in constants
the same way the prongs were:

| Part | Where | Why the operator might want it |
|---|---|---|
| the fist / hand plate | `mechanical_arms.gd` | it is right next to the claw |
| spider legs | `spider_solid.gd` | topic 1, "its body" |
| the spider's pincer arms | `enemy.gd` | topic 3, "its arms" |
| the spike | `main.gd` `_spawn_spikes()` | it is a shape with no behaviour at all — the easiest possible second part |

The spike is the honest first target after the claw: it does nothing
but sit there and be sharp, so getting it wrong costs nothing.

## Definition of Done

- [ ] One loader used by every part, not a copy per character.
- [ ] A part with no scene file behaves exactly as it does today —
      proved by the existing tests for that part passing unchanged.
- [ ] At least one part besides the claw is modellable, with the spike
      as the intended first.
- [ ] Adding a new modellable part is a one-line change plus a file.

## Out of scope

- Converting everything at once. The rule is the deliverable; each
  conversion is small and can happen when the operator wants to change
  that particular thing. Converting parts nobody wants to edit is work
  with no reader.
