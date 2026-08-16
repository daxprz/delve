---
xid: STO-TOOLS-014
parent: ./epic.md
kind: story
effort: tools
size: S
status: draft
date: 2026-08-16
depends-on: [STO-TOOLS-011, STO-TOOLS-013]
bd-id: delve-asan
---

# A blank part to copy when you make something new

## Summary

STO-TOOLS-011 makes the *claw* editable. This makes **a new thing**
possible.

Right now, starting a new part means knowing that the code wants
`J0 > (Seg, End > J1 > (Seg, End))` — a structure nobody should have
to memorise. So: `scenes/parts/_template_limb.tscn`, a two-block limb
with every node already named correctly, that gets copied and
reshaped.

The underscore prefix is deliberate: it sorts to the top of the folder
and marks it as the one file that is not a real part.

Named "a blank part" but it is not blank — it is the smallest thing
that already works, which is a much better starting point than an
empty scene. Same principle as STO-TOOLS-011's export: **editing beats
starting.**

## Definition of Done

- [ ] `scenes/parts/_template_limb.tscn` exists, correctly named
      throughout, and loads without complaint.
- [ ] Copying it and pointing something at the copy produces a working
      part with no other changes.
- [ ] A test loads the template and checks it satisfies the loader —
      so the template can never rot into an example that does not
      work, which is worse than no example.
- [ ] The guide (STO-TOOLS-015) says to start here.

## Out of scope

- Templates for anything other than a jointed limb. Whether a spider
  leg or a spike wants a different template is answered by
  STO-TOOLS-017, once there is more than one kind of part to compare.
